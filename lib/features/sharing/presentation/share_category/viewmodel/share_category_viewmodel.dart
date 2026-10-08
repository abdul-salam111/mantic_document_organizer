import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../core/local_storage/local_storage_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../categories/domain/entities/category_item.dart';
import '../../../../categories/domain/usecases/category_usecases.dart';
import '../../../../../core/background/document_sync_background_service.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../domain/entities/join_link_entity.dart';
import '../../../domain/entities/member_entity.dart';
import '../../../domain/entities/pending_invitation_entity.dart';
import '../../../domain/entities/space_role.dart';
import '../../../domain/usecases/member_count_cache.dart';
import '../../../domain/usecases/share_category_usecase.dart';
import '../../../domain/usecases/sharing_usecases.dart';

/// Drives the Share screen (see docs/space_sharing_ux_plan.txt §2) for one
/// category -- whether it's being shared for the very first time or is
/// already a shared space being revisited.
class ShareCategoryViewModel extends ChangeNotifier {
  final ShareCategoryUsecase _shareCategory;
  final ListMembersUsecase _listMembers;
  final UpdateMemberRoleUsecase _updateMemberRole;
  final RemoveMemberUsecase _removeMember;
  final InviteMemberUsecase _inviteMember;
  final ListInvitationsUsecase _listInvitations;
  final RevokeInvitationUsecase _revokeInvitation;
  final CreateJoinLinkUsecase _createJoinLink;
  final ListJoinLinksUsecase _listJoinLinks;
  final RevokeJoinLinkUsecase _revokeJoinLink;
  final CategoryUseCases _categoryUseCases;
  final DocumentSyncBackgroundService _syncBackgroundService;
  final MemberCountCache _memberCountCache;

  ShareCategoryViewModel({
    required ShareCategoryUsecase shareCategory,
    required ListMembersUsecase listMembers,
    required UpdateMemberRoleUsecase updateMemberRole,
    required RemoveMemberUsecase removeMember,
    required InviteMemberUsecase inviteMember,
    required ListInvitationsUsecase listInvitations,
    required RevokeInvitationUsecase revokeInvitation,
    required CreateJoinLinkUsecase createJoinLink,
    required ListJoinLinksUsecase listJoinLinks,
    required RevokeJoinLinkUsecase revokeJoinLink,
    required CategoryUseCases categoryUseCases,
    required DocumentSyncBackgroundService syncBackgroundService,
    required MemberCountCache memberCountCache,
  }) : _shareCategory = shareCategory,
       _listMembers = listMembers,
       _updateMemberRole = updateMemberRole,
       _removeMember = removeMember,
       _inviteMember = inviteMember,
       _listInvitations = listInvitations,
       _revokeInvitation = revokeInvitation,
       _createJoinLink = createJoinLink,
       _listJoinLinks = listJoinLinks,
       _revokeJoinLink = revokeJoinLink,
       _categoryUseCases = categoryUseCases,
       _syncBackgroundService = syncBackgroundService,
       _memberCountCache = memberCountCache;

  /// A fresh [ShareCategoryViewModel] starts with an empty placeholder --
  /// call this immediately after creating it (see ShareCategoryView),
  /// mirroring AddCategoryViewModel.startEditing's pattern of initializing
  /// per-screen state right after DI construction instead of through the
  /// constructor, since this ViewModel is registered with no per-use args.
  CategoryItem _category = const CategoryItem(id: '', name: '', iconKey: '');
  void initWith(CategoryItem category) {
    _category = category;
  }

  CategoryItem get category => _category;

  bool get isAlreadyShared => _category.spaceId != null;
  bool get isOwner => _category.myRole == SpaceRole.owner.value;

  bool isPreparing = false;
  bool isLoading = false;
  bool isSyncing = false;

  List<MemberEntity> members = const [];
  List<PendingInvitationEntity> pendingInvitations = const [];
  String? joinLinkUrl;
  bool isCreatingLink = false;
  bool isInviting = false;

  String? get _token => SessionController.instance.userToken;

  /// Creates the backend space + category for the very FIRST share of this
  /// category (see ShareCategoryUsecase) -- never called again for a
  /// category that's already shared (the UX plan's "no duplicate spaces"
  /// rule; callers must check [isAlreadyShared] first).
  Future<bool> shareNow() async {
    final token = _token;
    if (token == null) return false;
    isPreparing = true;
    notifyListeners();
    final result = await _shareCategory((token: token, category: _category));
    isPreparing = false;
    return result.fold(
      onFailure: (error) {
        AppToastsUtils.error(error.message);
        notifyListeners();
        return false;
      },
      onSuccess: (updated) {
        _category = updated;
        notifyListeners();
        unawaited(loadAll());
        return true;
      },
    );
  }

  Future<void> loadAll() async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null) return;
    isLoading = true;
    notifyListeners();

    final membersResult = await _listMembers((token: token, spaceId: spaceId));
    members = membersResult.fold(
      onFailure: (error) {
        AppToastsUtils.error(error.message);
        return members;
      },
      onSuccess: (value) => value,
    );
    _memberCountCache.setCount(spaceId, members.length);

    if (isOwner) {
      final invitationsResult = await _listInvitations((
        token: token,
        spaceId: spaceId,
      ));
      pendingInvitations = invitationsResult.fold(
        onFailure: (_) => pendingInvitations,
        onSuccess: (value) => value,
      );
      await _ensureJoinLink(token: token, spaceId: spaceId);
    }

    isLoading = false;
    notifyListeners();
  }

  /// The raw join-link token only ever exists right after creation -- a
  /// later listing only confirms an active link exists, it can't return
  /// the token again. So the shareable URL is cached locally per space the
  /// first time it's created, and reused on every later visit; if the
  /// stored token no longer matches an active link (e.g. a reinstall),
  /// a fresh one is created to replace it.
  Future<void> _ensureJoinLink({
    required String token,
    required String spaceId,
  }) async {
    final storageKey = '${StorageKeys.joinLinkTokenPrefix}$spaceId';
    final storedToken = await storage.readValues(storageKey);

    final linksResult = await _listJoinLinks((token: token, spaceId: spaceId));
    final hasActiveLink = linksResult.fold(
      onFailure: (_) => false,
      onSuccess: (links) => links.isNotEmpty,
    );

    if (storedToken != null && storedToken.isNotEmpty && hasActiveLink) {
      joinLinkUrl = DeepLinkService.joinSpaceUrl(storedToken);
      return;
    }

    isCreatingLink = true;
    notifyListeners();
    final result = await _createJoinLink((
      token: token,
      spaceId: spaceId,
      role: SpaceRole.editor,
      expiresInDays: null,
    ));
    isCreatingLink = false;
    result.fold(
      onFailure: (error) => AppToastsUtils.error(error.message),
      onSuccess: (JoinLinkEntity link) {
        final rawToken = link.token;
        if (rawToken == null) return;
        unawaited(storage.setValues(storageKey, rawToken));
        joinLinkUrl = DeepLinkService.joinSpaceUrl(rawToken);
      },
    );
  }

  Future<bool> inviteByEmail({
    required String email,
    required SpaceRole role,
  }) async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null) return false;
    isInviting = true;
    notifyListeners();
    final result = await _inviteMember((
      token: token,
      spaceId: spaceId,
      email: email,
      role: role,
    ));
    isInviting = false;
    return result.fold(
      onFailure: (error) {
        AppToastsUtils.error(error.message);
        notifyListeners();
        return false;
      },
      onSuccess: (invitation) {
        pendingInvitations = [...pendingInvitations, invitation];
        notifyListeners();
        AppToastsUtils.success('Invite sent to $email.');
        return true;
      },
    );
  }

  Future<void> revokeInvitation(String invitationId) async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null) return;
    final result = await _revokeInvitation((
      token: token,
      spaceId: spaceId,
      invitationId: invitationId,
    ));
    result.fold(
      onFailure: (error) => AppToastsUtils.error(error.message),
      onSuccess: (_) {
        pendingInvitations = pendingInvitations
            .where((invitation) => invitation.id != invitationId)
            .toList(growable: false);
        notifyListeners();
      },
    );
  }

  Future<void> updateMemberRole({
    required String userId,
    required SpaceRole role,
  }) async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null) return;
    final result = await _updateMemberRole((
      token: token,
      spaceId: spaceId,
      userId: userId,
      role: role,
    ));
    result.fold(
      onFailure: (error) => AppToastsUtils.error(error.message),
      onSuccess: (_) async {
        await loadAll();
      },
    );
  }

  Future<void> removeMember(String userId) async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null) return;
    final result = await _removeMember((
      token: token,
      spaceId: spaceId,
      userId: userId,
    ));
    result.fold(
      onFailure: (error) => AppToastsUtils.error(error.message),
      onSuccess: (_) {
        members = members
            .where((member) => member.userId != userId)
            .toList(growable: false);
        _memberCountCache.invalidate(spaceId);
        notifyListeners();
      },
    );
  }

  /// Revokes the current reusable join link and replaces it with a brand
  /// new one -- e.g. if the owner suspects the old link/QR was shared too
  /// widely. Everyone who already joined keeps their membership; only the
  /// old link itself stops working.
  Future<void> regenerateLink() async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null || !isOwner) return;
    final storageKey = '${StorageKeys.joinLinkTokenPrefix}$spaceId';

    final linksResult = await _listJoinLinks((token: token, spaceId: spaceId));
    final activeLinks = linksResult.fold(
      onFailure: (_) => const <JoinLinkEntity>[],
      onSuccess: (links) => links,
    );
    isCreatingLink = true;
    notifyListeners();
    for (final link in activeLinks) {
      await _revokeJoinLink((token: token, spaceId: spaceId, joinLinkId: link.id));
    }
    await storage.clearValues(storageKey);
    joinLinkUrl = null;
    isCreatingLink = false;
    await _ensureJoinLink(token: token, spaceId: spaceId);
    notifyListeners();
  }

  Future<void> syncNow() async {
    final token = _token;
    final spaceId = _category.spaceId;
    if (token == null || spaceId == null || isSyncing) return;
    isSyncing = true;
    notifyListeners();
    try {
      await _syncBackgroundService.runSpaceSync(
        token: token,
        spaceId: spaceId,
        isPersonalSpace: false,
      );
      // The sync may have changed this category (e.g. a rename pulled from
      // another owner's device) -- re-read it from the now-refreshed cache.
      final refreshed = _categoryUseCases.byId(_category.id);
      if (refreshed != null) _category = refreshed;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
