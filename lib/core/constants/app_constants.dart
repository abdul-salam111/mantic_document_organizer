class AppConstants {
  /// Feature switch for gallery/filesystem-based document discovery and
  /// import -- covers the manual Profile entry points ("Import documents",
  /// "Find more documents"). See [autoImportEnabled] for the separate,
  /// unsolicited automatic scan.
  static const bool bulkImportEnabled = true;

  /// Separate switch for the *unsolicited* parts of bulk import: the
  /// one-time consent sheet shown automatically on first launch
  /// (AutoImportConsentSheet, see navbar_view.dart) and
  /// AutoImportService's resulting one-time automatic scan. Kept false
  /// while [bulkImportEnabled] is true so the manual "Import documents"/
  /// "Find more documents" Profile tiles stay available without the app
  /// prompting the user to scan their whole library on its own.
  static const bool autoImportEnabled = false;

  /// The numeric App Store Connect ID Apple assigns once the app exists
  /// there (App Information page) -- required by
  /// InAppReview.openStoreListing's iOS fallback, used only when the
  /// native StoreKit review prompt isn't available. Fill this in once the
  /// app has been created in App Store Connect; until then the iOS
  /// fallback link can't resolve to the real listing.
  static const String iosAppStoreId = '';
}
