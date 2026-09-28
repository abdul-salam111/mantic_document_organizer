import 'package:flutter/foundation.dart';

import '../../../../../../../core/notifications/notifications_exports.dart';
import '../../../../../../home/home_exports.dart';

/// Active documents due within [ExpiryNotificationService.digestWindowDays]
/// — the destination for tapping the weekly "N documents expire this
/// month" digest notification (see
/// [ExpiryNotificationService.scheduleWeeklyDigest]). Same "read straight
/// from the shared local store" pattern as TrashViewModel/
/// CategoryDocumentsViewModel.
class ExpiringSoonViewModel extends ChangeNotifier {
  final DocumentLocalStore _documentStore;

  ExpiringSoonViewModel({required DocumentLocalStore documentStore})
    : _documentStore = documentStore {
    _documentStore.addListener(notifyListeners);
  }

  /// Soonest-expiring first — matches the digest notification's own count
  /// exactly (same window, same active-document source).
  List<DocumentItem> get documents {
    final now = DateTime.now();
    final windowEnd = now.add(
      const Duration(days: ExpiryNotificationService.digestWindowDays),
    );
    final matches = _documentStore.documents.where((d) {
      final expiry = d.expiryDate;
      return d.isExpirable &&
          expiry != null &&
          expiry.isAfter(now) &&
          expiry.isBefore(windowEnd);
    }).toList();
    matches.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return matches;
  }

  void toggleFavorite(DocumentItem document) =>
      _documentStore.toggleFavorite(document);

  @override
  void dispose() {
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
