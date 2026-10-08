import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../features/sharing/sharing_exports.dart';
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

  final AcceptInvitationUsecase _acceptInvitation;
  final AcceptJoinLinkUsecase _acceptJoinLink;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;

  DeepLinkService({
    required AcceptInvitationUsecase acceptInvitation,
    required AcceptJoinLinkUsecase acceptJoinLink,
    AppLinks? appLinks,
  }) : _acceptInvitation = acceptInvitation,
       _acceptJoinLink = acceptJoinLink,
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

    // TODO(sharing-ui): once the "Joining... -> You've joined X" screen
    // exists (see docs/space_sharing_ux_plan.txt §3), route there instead
    // of toasting -- this is intentionally the thinnest possible feedback
    // until that screen lands.
    final result = kind == _JoinKind.invitation
        ? await _acceptInvitation((token: accessToken, invitationToken: token))
        : await _acceptJoinLink((token: accessToken, joinLinkToken: token));

    result.fold(
      onFailure: (error) => AppToastsUtils.error(error.message),
      onSuccess: (joined) {
        AppToastsUtils.success("You've joined ${joined.space.name}");
        AppNavigator.goNamed(RouteNames.home);
      },
    );
  }
}
