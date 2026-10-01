import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter/services.dart' show PlatformException;
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
}

class SocialIdentityDataSourceImpl implements ISocialIdentityDataSource {
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // The Web client ID is the audience FastAPI verifies. This deliberately
    // uses the legacy native flow, avoiding Android Credential Manager.
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );

  @override
  Future<SocialIdentity> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) throw AuthenticationCancelledException();
      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AppException('Google did not return an identity token.');
      }
      return SocialIdentity(idToken: idToken, displayName: account.displayName);
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'Google sign-in failed '
        '(code: ${error.code}, message: ${error.message}, '
        'details: ${error.details})',
      );
      debugPrintStack(
        label: 'Google sign-in stack trace',
        stackTrace: stackTrace,
      );
      if (error.code == GoogleSignIn.kSignInCanceledError) {
        throw AuthenticationCancelledException();
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
        throw AuthenticationCancelledException();
      }
      throw AppException('Apple sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signOutGoogle() => _googleSignIn.signOut();

  String get _googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
}
