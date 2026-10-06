/// API endpoint paths for this project.
///
/// The FastAPI Cloud production API. It deliberately ends at the versioned
/// API prefix so feature data sources only name their own resource paths.
class ApiEndPoints {
  static const baseUrl =
      'https://mantic-doc-org-backend-341ceb3a.fastapicloud.dev/api/v1/';
  static const String signIn = '${baseUrl}auth/sign-in';
  static const String signUp = '${baseUrl}auth/sign-up';
  static const String signInWithGoogle = '${baseUrl}auth/sign-in/google';
  static const String signInWithApple = '${baseUrl}auth/sign-in/apple';
  static const String signOut = '${baseUrl}auth/sign-out';
  static const String refresh = '${baseUrl}auth/refresh';
  static const String verifyEmail = '${baseUrl}auth/verify-email';
  static const String resendVerificationEmail =
      '${baseUrl}auth/resend-verification-email';
  static const String currentUser = '${baseUrl}auth/me';
  static const String spaces = '${baseUrl}spaces';
  static const String storageConnections = '${baseUrl}storage/connections';
  static const String googleDriveAuthorizationUrl =
      '${baseUrl}storage/google/authorization-url';
  static const String search = "${baseUrl}search";
  static const String favorites = "${baseUrl}favorites";
  static const String addDocument = "${baseUrl}documents";
  static const String aiAssistant = "${baseUrl}ai-assistant";
}
