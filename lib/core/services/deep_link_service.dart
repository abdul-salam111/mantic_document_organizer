import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../features/sharing/sharing_exports.dart';
import '../background/document_sync_background_service.dart';
import '../local_storage/local_storage_exports.dart';
import '../utils/utils_exports.dart';
import '../../routes/routes_exports.dart';
import 'session_manager.dart';

enum _JoinKind { invitation, joinLink }

/// Catches the `com.mantic.document.organizer://` links a "share a
/// category" invitation/join-link produces (see
/// docs/space_sharing_ux_plan.txt) -- on cold start (`getInitialLink`) and
/// while the app is already running (`uriLinkStream`) -- and resolves them
/// against the backend's accept endpoints.
///
/// If the person isn't signed in yet, the raw token is held in local
/// storage and redeemed automatically right after their next successful
/// sign-in -- see [resumePendingIfAny], called from SigninViewModel.
class DeepLinkService {
  /// Shared with whatever builds a join-link's shareable URL (the Share
  /// screen) -- must match the backend's `FRONTEND_DEEP_LINK` env var and
  /// the scheme registered in the native manifests.
  static const String deepLinkScheme = 'com.mantic.document.organizer';

  /// The shareable URL a join link's QR code/copy-link button encodes --
  /// the inverse of [_handleUri]'s `join-space` branch below.
  static String joinSpaceUrl(String token) =>
      '$deepLinkScheme://join-space?token=$token';

  final AcceptInvitationUsecase _acceptInvitation;
  final AcceptJoinLinkUsecase _acceptJoinLink;
  final DocumentSyncBackgroundService _syncBackgroundService;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;

  DeepLinkService({
    required AcceptInvitationUsecase acceptInvitation,
    required AcceptJoinLinkUsecase acceptJoinLink,
    required DocumentSyncBackgroundService syncBackgroundService,
    AppLinks? appLinks,
  }) : _acceptInvitation = acceptInvitation,
       _acceptJoinLink = acceptJoinLink,
       _syncBackgroundService = syncBackgroundService,
       _appLinks = appLinks ?? AppLinks();

  Future<void> init() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) await _handleUri(initialLink);

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stack) {
        if (kDebugMode) debugPrint('DeepLinkService stream error: $error');
      },
    );
  }

  void dispose() => _subscription?.cancel();

  /// Entry point for a QR payload read directly off-camera
  /// (JoinSpaceScanView) or a link pasted into its "Enter link manually"
  /// fallback -- same resolution as a tapped OS link, just without going
  /// through [AppLinks] at all.
  void handleScannedLink(Uri uri) => unawaited(_handleUri(uri));

  Future<void> _handleUri(Uri uri) async {
    if (uri.scheme != deepLinkScheme) return;

    // Different platforms/OS versions have put the same segment in either
    // `host` or `path` for this app's other custom-scheme callback (see
    // BackupSetupPage._handleDriveCallback) -- check both here too.
    final segment = uri.host.isNotEmpty
        ? uri.host
        : uri.path.replaceFirst('/', '');
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final kind = switch (segment) {
      'accept-invitation' => _JoinKind.invitation,
      'join-space' => _JoinKind.joinLink,
      _ => null,
    };
    if (kind == null) return;

    await _resolve(token: token, kind: kind);
  }

  Future<void> _resolve({required String token, required _JoinKind kind}) async {
    if (!SessionController.instance.islogin) {
      await storage.setValues(StorageKeys.pendingSpaceJoinToken, token);
      await storage.setValues(StorageKeys.pendingSpaceJoinKind, kind.name);
      AppNavigator.goNamed(RouteNames.signin);
      return;
    }
    await _accept(token: token, kind: kind);
  }

  /// Call right after a successful sign-in/sign-up -- redeems whatever
  /// token a deep link stashed while the person was signed out.
  Future<void> resumePendingIfAny() async {
    final token = await storage.readValues(StorageKeys.pendingSpaceJoinToken);
    final kindName = await storage.readValues(StorageKeys.pendingSpaceJoinKind);
    if (token == null || token.isEmpty || kindName == null) return;

    await storage.clearValues(StorageKeys.pendingSpaceJoinToken);
    await storage.clearValues(StorageKeys.pendingSpaceJoinKind);

    final kind = _JoinKind.values.asNameMap()[kindName];
    if (kind == null) return;
    await _accept(token: token, kind: kind);
  }

  Future<void> _accept({required String token, required _JoinKind kind}) async {
    final accessToken = SessionController.instance.userToken;
    if (accessToken == null) return;

    AppToastsUtils.loading('Joining…');
    final result = kind == _JoinKind.invitation
        ? await _acceptInvitation((token: accessToken, invitationToken: token))
        : await _acceptJoinLink((token: accessToken, joinLinkToken: token));
    AppToastsUtils.dismissCurrent();

    await result.fold(
      onFailure: (error) async => AppToastsUtils.error(error.message),
      onSuccess: (joined) async {
        // Pulls the newly joined space's category (and any existing
        // documents in it) down locally before showing the result screen,
        // so its "Open [Space Name]" button has somewhere real to go --
        // see DocumentSyncService's isPersonalSpace scoping.
        await _syncBackgroundService.runSpaceSync(
          token: accessToken,
          spaceId: joined.space.id,
          isPersonalSpace: false,
          newCategoryRole: joined.role.value,
        );
        AppNavigator.goNamed(
          RouteNames.joinResult,
          extra: (joined.space, joined.role),
        );
      },
    );
  }
}
