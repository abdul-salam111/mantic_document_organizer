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
  /// **'Search documents'**
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

  /// Profile menu entry, shown when signed in
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

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

  /// Add Document empty state title
  ///
  /// In en, this message translates to:
  /// **'Add a document'**
  String get addADocument;

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
