// FILE: lib/core/networks/exceptions/firebase_auth_exceptions.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'app_exceptions.dart';

// Firebase Auth exceptions — one [AppException] subtype per
// [fb.FirebaseAuthException.code] this app actually distinguishes in UI
// copy. Codes are documented at
// https://firebase.google.com/docs/reference/dart/firebase_auth/latest/firebase_auth/FirebaseAuthException-class.html

class InvalidEmailAuthException extends AppException {
  InvalidEmailAuthException([String? message])
    : super(message, "Invalid Email: ");
}

class UserDisabledAuthException extends AppException {
  UserDisabledAuthException([String? message])
    : super(message, "Account Disabled: ");
}

class UserNotFoundAuthException extends AppException {
  UserNotFoundAuthException([String? message])
    : super(message, "Account Not Found: ");
}

class WrongPasswordAuthException extends AppException {
  WrongPasswordAuthException([String? message])
    : super(message, "Incorrect Password: ");
}

class EmailAlreadyInUseAuthException extends AppException {
  EmailAlreadyInUseAuthException([String? message])
    : super(message, "Email Already Registered: ");
}

class WeakPasswordAuthException extends AppException {
  WeakPasswordAuthException([String? message])
    : super(message, "Weak Password: ");
}

class OperationNotAllowedAuthException extends AppException {
  OperationNotAllowedAuthException([String? message])
    : super(message, "Sign-In Method Disabled: ");
}

class TooManyRequestsAuthException extends AppException {
  TooManyRequestsAuthException([String? message])
    : super(message, "Too Many Attempts: ");
}

class NetworkRequestFailedAuthException extends AppException {
  NetworkRequestFailedAuthException([String? message])
    : super(message, "Network Error: ");
}

class InvalidCredentialAuthException extends AppException {
  InvalidCredentialAuthException([String? message])
    : super(message, "Invalid Credentials: ");
}

class CredentialAlreadyInUseAuthException extends AppException {
  CredentialAlreadyInUseAuthException([String? message])
    : super(message, "Credential Already Linked: ");
}

class RequiresRecentLoginAuthException extends AppException {
  RequiresRecentLoginAuthException([String? message])
    : super(message, "Please Sign In Again: ");
}

class UserTokenExpiredAuthException extends AppException {
  UserTokenExpiredAuthException([String? message])
    : super(message, "Session Expired: ");
}

class FirebaseUnknownAuthException extends AppException {
  FirebaseUnknownAuthException([String? message])
    : super(message, "Authentication Error: ");
}

/// Translates a [fb.FirebaseAuthException] into this app's own
/// [AppException] vocabulary by `.code` — the same job `DioHelper`'s
/// `_handleDioError` does for HTTP status codes — so nothing above
/// `FirebaseAuthHelper` ever needs to know Firebase-specific error codes
/// exist. Falls back to [FirebaseUnknownAuthException] (carrying the raw
/// code) for any code not explicitly handled below, rather than throwing
/// the raw [fb.FirebaseAuthException] through — every caller of
/// `FirebaseAuthHelper` can assume it only ever sees [AppException]s.
AppException mapFirebaseAuthException(fb.FirebaseAuthException e) {
  final message = e.message;
  switch (e.code) {
    case 'invalid-email':
      return InvalidEmailAuthException(
        message ?? 'The email address is badly formatted.',
      );
    case 'user-disabled':
      return UserDisabledAuthException(
        message ?? 'This account has been disabled.',
      );
    case 'user-not-found':
      return UserNotFoundAuthException(
        message ?? 'No account found for this email.',
      );
    case 'wrong-password':
      return WrongPasswordAuthException(message ?? 'Incorrect password.');
    case 'email-already-in-use':
      return EmailAlreadyInUseAuthException(
        message ?? 'An account already exists for this email.',
      );
    case 'weak-password':
      return WeakPasswordAuthException(
        message ?? 'The password is too weak.',
      );
    case 'operation-not-allowed':
      return OperationNotAllowedAuthException(
        message ?? 'Email/password sign-in is disabled for this project.',
      );
    case 'too-many-requests':
      return TooManyRequestsAuthException(
        message ?? 'Too many attempts. Try again later.',
      );
    case 'network-request-failed':
      return NetworkRequestFailedAuthException(
        message ?? 'Please check your network connection.',
      );
    case 'invalid-credential':
      return InvalidCredentialAuthException(
        message ?? 'The provided credentials are invalid or expired.',
      );
    case 'credential-already-in-use':
      return CredentialAlreadyInUseAuthException(
        message ?? 'These credentials are already linked to another account.',
      );
    case 'requires-recent-login':
      return RequiresRecentLoginAuthException(
        message ?? 'Please sign in again to continue.',
      );
    case 'user-token-expired':
    case 'user-mismatch':
      return UserTokenExpiredAuthException(
        message ?? 'Your session has expired. Please sign in again.',
      );
    default:
      return FirebaseUnknownAuthException(message ?? 'code: ${e.code}');
  }
}
