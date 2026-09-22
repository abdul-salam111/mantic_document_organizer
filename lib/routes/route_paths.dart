class RoutePaths {
  /// The app always boots to splash first — it's the one that decides
  /// (via StorageKeys.hasSeenOnboarding) whether to continue to
  /// [onboarding] or straight to [home].
  static const String initialRoute = splash;
  static const String splash = "/splash";
  static const String signin = "/signin";
  static const String signup = "/signup";
  static const String home = "/home";
  static const String addDocument = "/add-document";
  static const String onboarding = "/onboarding";

  // GENERATED_ROUTE_PATHS_START

  // GENERATED_ROUTE_PATHS_END
}
