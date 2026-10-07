class AppConstants {
  /// Feature switch for gallery/filesystem-based document discovery and
  /// import -- covers both the manual "Find more documents" entry point and
  /// AutoImportService's one-time automatic scan, which share the same
  /// review screen.
  static const bool bulkImportEnabled = false;
}
