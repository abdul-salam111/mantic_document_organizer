import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/networks/exceptions/app_exceptions.dart';

class SocialIdentity {
  final String idToken;
  final String? displayName;

  const SocialIdentity({required this.idToken, this.displayName});
}

/// Obtains identity tokens from the platform SDKs. It deliberately does not
/// make HTTP requests; token exchange remains in [RemoteAuthDataSourceImpl].
abstract interface class ISocialIdentityDataSource {
  Future<SocialIdentity> signInWithGoogle();
  Future<SocialIdentity> signInWithApple();
  Future<void> signOutGoogle();
  Future<String> requestGoogleDriveAuthorizationCode();
}

class SocialIdentityDataSourceImpl implements ISocialIdentityDataSource {
  Future<void>? _googleInitialization;

  @override
  Future<SocialIdentity> signInWithGoogle() async {
    await _initializeGoogle();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AppException('Google did not return an identity token.');
      }
      return SocialIdentity(idToken: idToken, displayName: account.displayName);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AppException('Google sign-in was cancelled.');
      }
      throw AppException('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<SocialIdentity> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw AppException('Apple did not return an identity token.');
      }
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
      return SocialIdentity(
        idToken: identityToken,
        displayName: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw AppException('Apple sign-in was cancelled.');
      }
      throw AppException('Apple sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signOutGoogle() => GoogleSignIn.instance.disconnect();

  @override
  Future<String> requestGoogleDriveAuthorizationCode() async {
    await _initializeGoogle();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.file'],
      );
      final authorization = await account.authorizationClient.authorizeServer(
        const ['https://www.googleapis.com/auth/drive.file'],
      );
      if (authorization == null || authorization.serverAuthCode.isEmpty) {
        throw AppException('Google Drive authorization was not completed.');
      }
      return authorization.serverAuthCode;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AppException('Google Drive connection was cancelled.');
      }
      throw AppException('Google Drive connection failed. Please try again.');
    }
  }

  Future<void> _initializeGoogle() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize(
      // Android requires the backend's Web OAuth client ID when the app does
      // not use google-services.json. The public ID comes from .env; iOS
      // still reads its native client ID from Info.plist.
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
  }

  String get _googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
}
