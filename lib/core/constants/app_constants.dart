class AppConstants {
  /// Feature switch for gallery/filesystem-based document discovery and
  /// import -- covers both the manual "Find more documents" entry point and
  /// AutoImportService's one-time automatic scan, which share the same
  /// review screen.
  static const bool bulkImportEnabled = false;

  /// The numeric App Store Connect ID Apple assigns once the app exists
  /// there (App Information page) -- required by
  /// InAppReview.openStoreListing's iOS fallback, used only when the
  /// native StoreKit review prompt isn't available. Fill this in once the
  /// app has been created in App Store Connect; until then the iOS
  /// fallback link can't resolve to the real listing.
  static const String iosAppStoreId = '';
}
