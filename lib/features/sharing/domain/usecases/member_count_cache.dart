import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/services_exports.dart';
import 'sharing_usecases.dart';

/// A shared-category's member count isn't known locally (see
/// CategoryItem), so showing it anywhere -- Manage Categories' row badge,
/// Home's tile badge -- means a network call. This caches that call per
/// spaceId so the two screens (or two rows) never double-fetch the same
/// space, and is a lazy singleton (see sharingDependencies()) rather than
/// per-ViewModel state for exactly that reason.
class MemberCountCache extends ChangeNotifier {
  final ListMembersUsecase _listMembers;

  MemberCountCache(this._listMembers);

  final Map<String, int> _counts = {};
  final Set<String> _fetching = {};

  /// Null while the count hasn't arrived yet (or couldn't be fetched) --
  /// callers show a plain badge with no number until a later rebuild
  /// (triggered by this cache's own [notifyListeners]) has it.
  int? countFor(String spaceId) {
    final cached = _counts[spaceId];
    if (cached != null) return cached;
    unawaited(_fetch(spaceId));
    return null;
  }

  /// Call after an action that could change a space's membership (e.g.
  /// just after the owner removes a member) so the next [countFor] call
  /// re-fetches instead of serving a stale cached count.
  void invalidate(String spaceId) => _counts.remove(spaceId);

  /// Call when a caller already fetched an authoritative member list for
  /// [spaceId] (e.g. ShareCategoryViewModel.loadAll) -- updates the cache
  /// directly instead of making every other screen showing this space's
  /// badge pay for a second, redundant fetch.
  void setCount(String spaceId, int count) {
    if (_counts[spaceId] == count) return;
    _counts[spaceId] = count;
    notifyListeners();
  }

  Future<void> _fetch(String spaceId) async {
    final token = SessionController.instance.userToken;
    if (token == null || !_fetching.add(spaceId)) return;
    try {
      final result = await _listMembers((token: token, spaceId: spaceId));
      result.fold(
        onFailure: (_) {},
        onSuccess: (members) {
          _counts[spaceId] = members.length;
          notifyListeners();
        },
      );
    } finally {
      _fetching.remove(spaceId);
    }
  }
}
