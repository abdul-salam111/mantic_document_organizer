/// API endpoint paths for this project.
///
/// [baseUrl] is a placeholder — this project has no environment/flavor
/// strategy yet (dev vs. prod URLs, `--dart-define`, etc.). Point this at
/// real config instead of hardcoding a domain here.
class ApiEndPoints {
  static const baseUrl = "https://api.example.com/v1/";
  static const String loginByUid = "${baseUrl}auth/login";
  static const String signupUser = "${baseUrl}auth/signup";
}
