import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Subtitle shown under the logo on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Document Organizer'**
  String get splashTagline;

  /// Onboarding screen headline
  ///
  /// In en, this message translates to:
  /// **'All Your Documents,\nBeautifully Organized'**
  String get onboardingHeadline;

  /// Onboarding screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Scan, categorize, and find every important document in seconds — all stored securely on your device, even offline.'**
  String get onboardingSubtitle;

  /// Onboarding CTA button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// Onboarding reassurance line under the CTA
  ///
  /// In en, this message translates to:
  /// **'No sign-in required — your documents stay on this device.'**
  String get onboardingNoSignIn;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'All Docs'**
  String get navAllDocs;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// Home screen search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search categories and documents'**
  String get homeSearchHint;

  /// Home screen section heading
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recentFiles;

  /// Link that jumps to All Docs
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Home screen section heading
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Fallback category tile shown after all real categories
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// Add-a-category tile at the end of the category grid/list
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// File count shown under a category
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file} other{{count} files}}'**
  String fileCount(int count);

  /// Search result count shown next to sort/view controls once a query is typed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} result} other{{count} results}}'**
  String resultsCount(int count);

  /// Tooltip on Home's header profile icon button
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// All Docs screen title
  ///
  /// In en, this message translates to:
  /// **'All Docs'**
  String get allDocsTitle;

  /// All Docs screen search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search documents or categories'**
  String get allDocsSearchHint;

  /// The first category tab, showing every document
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategoryTab;

  /// Empty state title on All Docs
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// Empty state subtitle when a category tab has no documents and no search is active
  ///
  /// In en, this message translates to:
  /// **'Nothing in \"{category}\" yet'**
  String nothingInCategoryYet(String category);

  /// Empty state subtitle when a search query has no matches within a category
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\" in \"{category}\"'**
  String nothingMatchesQueryInCategory(String query, String category);

  /// Empty state subtitle when a search query has no matches, with no category scope (e.g. Favorites)
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String nothingMatchesQuery(String query);

  /// Favorites screen title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// Favorites empty state title
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Favorites empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Documents you favorite will show up here'**
  String get favoritesEmptySubtitle;

  /// Tooltip on a favorite tile's heart button
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile header name shown when signed out
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// Profile header name fallback when signed in but no name is on file
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Profile header subtitle shown when signed out
  ///
  /// In en, this message translates to:
  /// **'Local-only — your documents stay on this device'**
  String get localOnlyStatus;

  /// CTA button shown when signed out
  ///
  /// In en, this message translates to:
  /// **'Set up backup'**
  String get setUpBackup;

  /// Profile menu entry
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// Profile menu entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Recover recently deleted documents'**
  String get trashSubtitle;

  /// Profile menu entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Appearance, language, categories & security'**
  String get settingsSubtitle;

  /// Profile menu entry, shown when signed in
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Profile stats row label
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get statDocuments;

  /// Profile stats row label
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get statCategories;

  /// Profile stats row label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get statFavorites;

  /// Settings screen title / Profile menu entry
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings section heading
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme mode option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// Theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings section heading for the language picker
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Settings menu entry
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// Settings menu entry
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// manage_categories search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// manage_categories empty search result
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// New Category screen text field label
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameLabel;

  /// New Category screen text field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Bank Statements'**
  String get categoryNameHint;

  /// New Category screen validation message
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// New Category screen validation message when the name is a duplicate
  ///
  /// In en, this message translates to:
  /// **'This category already exists'**
  String get categoryNameTaken;

  /// New Category screen section heading
  ///
  /// In en, this message translates to:
  /// **'Choose an Icon'**
  String get chooseIcon;

  /// Icon picker sheet search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get searchIcons;

  /// Icon picker sheet empty search result
  ///
  /// In en, this message translates to:
  /// **'No icons found'**
  String get noIconsFound;

  /// New Category screen section heading
  ///
  /// In en, this message translates to:
  /// **'Choose a Color'**
  String get chooseColor;

  /// New Category screen submit button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Generic confirm button, e.g. closing the color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Success toast shown after creating a category
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" category created'**
  String categoryCreatedToast(String name);

  /// Edit Category screen title / manage_categories row edit button tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// Edit Category screen submit button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Success toast shown after editing a category
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" category updated'**
  String categoryUpdatedToast(String name);

  /// manage_categories row delete button tooltip / confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// Confirm dialog body shown before deleting a category
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This can\'t be undone.'**
  String deleteCategoryConfirm(String name);

  /// Destructive confirm dialog action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Success toast shown after deleting a category
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" category deleted'**
  String categoryDeletedToast(String name);

  /// manage_categories multi-select app bar title
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// Confirm dialog body shown before bulk-deleting selected categories
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete this category? This can\'t be undone.} other{Delete {count} categories? This can\'t be undone.}}'**
  String deleteCategoriesConfirm(int count);

  /// Success toast shown after bulk-deleting selected categories
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Category deleted} other{{count} categories deleted}}'**
  String categoriesDeletedToast(int count);

  /// Settings section heading
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Settings toggle label for biometric app lock (fingerprint hardware)
  ///
  /// In en, this message translates to:
  /// **'Fingerprint Unlock'**
  String get biometricUnlock;

  /// Settings toggle label for biometric app lock (iOS Face ID hardware)
  ///
  /// In en, this message translates to:
  /// **'Face ID Unlock'**
  String get faceIdUnlock;

  /// Settings toggle label for biometric app lock (iOS Touch ID hardware)
  ///
  /// In en, this message translates to:
  /// **'Touch ID Unlock'**
  String get touchIdUnlock;

  /// Settings toggle label for biometric app lock (unknown/mixed hardware)
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricUnlockGeneric;

  /// Settings toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Require your fingerprint or face to open the app'**
  String get biometricUnlockSubtitle;

  /// Toast shown when the device has no usable biometrics
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication isn\'t set up on this device'**
  String get biometricUnavailable;

  /// Toast shown when a biometric prompt fails or is cancelled
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get biometricAuthFailed;

  /// Reason string shown inside the OS biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get biometricPromptReason;

  /// Settings section heading
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Settings menu entry
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Settings menu entry
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// Text passed to the OS share sheet from Share App
  ///
  /// In en, this message translates to:
  /// **'Check out Mantic Document Organizer — scan, organize, and find every important document in seconds.'**
  String get shareAppMessage;

  /// Lock screen title
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLocked;

  /// Lock screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get unlockToContinue;

  /// Lock screen button label
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// Add Document screen title
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocumentTitle;

  /// Edit Document screen title / document viewer edit button tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit file'**
  String get editDocumentTitle;

  /// Add Document screen text field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get documentTitleLabel;

  /// Add Document screen text field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Passport Scan'**
  String get documentTitleHint;

  /// Add Document screen validation message
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get documentTitleRequired;

  /// Add Document screen category picker caption
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Add Document screen category picker sheet heading
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Add Document screen text field label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Add Document screen text field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. invoice-2026'**
  String get tagsHint;

  /// Add Document screen tags field helper text explaining the input rules
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers, - and _ only, up to {maxLength} characters each'**
  String tagsHelper(int maxLength);

  /// Add Document screen tag validation error
  ///
  /// In en, this message translates to:
  /// **'You can add up to {maxCount} tags'**
  String tagErrorLimitReached(int maxCount);

  /// Add Document screen tag validation error
  ///
  /// In en, this message translates to:
  /// **'Tags must be {maxLength} characters or fewer'**
  String tagErrorTooLong(int maxLength);

  /// Add Document screen tag validation error
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, - and _ only (no spaces)'**
  String get tagErrorInvalidCharacters;

  /// Add Document screen tag validation error
  ///
  /// In en, this message translates to:
  /// **'That tag is already added'**
  String get tagErrorDuplicate;

  /// Add Document screen toggle row label
  ///
  /// In en, this message translates to:
  /// **'This Document Expires'**
  String get documentExpirable;

  /// Add Document screen expiry toggle subtitle showing the picked date/time
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String expiresOn(String date);

  /// Add Document screen expiry toggle subtitle hint before a date is picked
  ///
  /// In en, this message translates to:
  /// **'Tap to set the expiry date and time'**
  String get tapToSetExpiryDate;

  /// Add Document screen section heading
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Add Document screen attachment source button label
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Add Document screen attachment source button label
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Add Document screen attachment source button label
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// Add Document screen warning toast when an image is picked via the Files button
  ///
  /// In en, this message translates to:
  /// **'Images aren\'t accepted here — use Camera or Gallery instead'**
  String get filesImagesNotAllowed;

  /// Add Document screen error toast when the document scanner fails
  ///
  /// In en, this message translates to:
  /// **'Scanning failed — please try again'**
  String get scanFailedToast;

  /// Success toast shown after saving a document
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added'**
  String documentCreatedToast(String name);

  /// Success toast shown after editing a document
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" updated'**
  String documentUpdatedToast(String name);

  /// Category Documents screen search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get searchDocumentsHint;

  /// Category Documents screen sort menu button tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Category Documents screen sort option
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// Category Documents screen sort option
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// Category Documents screen sort option
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAZ;

  /// Tooltip on a document tile's outline-heart button
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Document Viewer app bar action tooltip / unsupported-file-preview button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Document Viewer overflow menu entry
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Document Viewer overflow menu entry
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Document Viewer rename dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename Document'**
  String get renameDocument;

  /// Success toast shown after renaming a document
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String documentRenamedToast(String name);

  /// Success toast shown after moving a document to another category
  ///
  /// In en, this message translates to:
  /// **'Moved to \"{category}\"'**
  String documentMovedToast(String category);

  /// Document Viewer overflow menu entry / confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// Confirm dialog body shown before deleting a document
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This can\'t be undone.'**
  String deleteDocumentConfirm(String name);

  /// Success toast shown after deleting a document
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted'**
  String documentDeletedToast(String name);

  /// Document Viewer shown for an attachment that isn't an image (e.g. PDF/docx)
  ///
  /// In en, this message translates to:
  /// **'Preview not available for this file type'**
  String get noPreviewAvailable;

  /// Document Viewer info panel — when the document was created
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String addedOn(String date);

  /// Generic placeholder subtitle for an unbuilt screen
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Toast shown when tapping a not-yet-built item
  ///
  /// In en, this message translates to:
  /// **'{name} — coming soon'**
  String comingSoonToast(String name);

  /// Route error page title
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Route error page subtitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{path}\".'**
  String pageNotFoundSubtitle(String path);

  /// Route error page button
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
