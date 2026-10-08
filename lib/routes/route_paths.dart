class RoutePaths {
  /// The app always boots to splash first — it's the one that decides
  /// (via StorageKeys.hasSeenOnboarding) whether to continue to
  /// [onboarding] or straight to [home].
  static const String initialRoute = splash;
  static const String splash = "/splash";
  static const String signin = "/signin";
  static const String signup = "/signup";
  static const String backupSetup = "/backup-setup";
  static const String verifyEmail = "/verify-email";
  static const String home = "/home";
  static const String addDocument = "/add-document";
  static const String onboarding = "/onboarding";
  static const String settings = "/settings";
  static const String addCategory = "/add-category";
  static const String manageCategories = "/manage-categories";
  static const String categoryDocuments = "/category-documents";
  static const String documentViewer = "/document-viewer";
  static const String filePreview = "/file-preview";
  static const String trash = "/trash";
  static const String expiringSoon = "/expiring-soon";
  static const String bulkImport = "/bulk-import";
  static const String bulkImportReview = "/bulk-import-review";
  static const String shareCategory = "/share-category";
  static const String joinResult = "/join-result";
  static const String joinSpaceScan = "/join-space-scan";

  // GENERATED_ROUTE_PATHS_START

  static const String aiAssistant = "/ai-assistant";
  static const String sharing = "/sharing";
  // GENERATED_ROUTE_PATHS_END
}
