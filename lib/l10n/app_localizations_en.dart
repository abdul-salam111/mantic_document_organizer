// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashTagline => 'Document Organizer';

  @override
  String get onboardingHeadline => 'All Your Documents,\nBeautifully Organized';

  @override
  String get onboardingSubtitle =>
      'Scan, categorize, and find every important document in seconds — all stored securely on your device, even offline.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingNoSignIn =>
      'No sign-in required — your documents stay on this device.';

  @override
  String get navHome => 'Home';

  @override
  String get navAllDocs => 'All Docs';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get homeSearchHint => 'Search categories and documents';

  @override
  String get recentFiles => 'Recent Files';

  @override
  String get seeAll => 'See all';

  @override
  String get categories => 'Categories';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get newCategory => 'New Category';

  @override
  String fileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '$count file',
    );
    return '$_temp0';
  }

  @override
  String get profileTooltip => 'Profile';

  @override
  String get allDocsTitle => 'All Docs';

  @override
  String get allDocsSearchHint => 'Search documents or categories';

  @override
  String get allCategoryTab => 'All';

  @override
  String get noDocumentsFound => 'No documents found';

  @override
  String nothingInCategoryYet(String category) {
    return 'Nothing in \"$category\" yet';
  }

  @override
  String nothingMatchesQueryInCategory(String query, String category) {
    return 'Nothing matches \"$query\" in \"$category\"';
  }

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Documents you favorite will show up here';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get profileTitle => 'Profile';

  @override
  String get guest => 'Guest';

  @override
  String get account => 'Account';

  @override
  String get localOnlyStatus =>
      'Local-only — your documents stay on this device';

  @override
  String get setUpBackup => 'Set up backup';

  @override
  String get trash => 'Trash';

  @override
  String get signOut => 'Sign Out';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get addCategory => 'Add Category';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get searchCategories => 'Search categories';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get categoryNameLabel => 'Category Name';

  @override
  String get categoryNameHint => 'e.g. Bank Statements';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryNameTaken => 'This category already exists';

  @override
  String get chooseIcon => 'Choose an Icon';

  @override
  String get searchIcons => 'Search icons';

  @override
  String get noIconsFound => 'No icons found';

  @override
  String get chooseColor => 'Choose a Color';

  @override
  String get create => 'Create';

  @override
  String get done => 'Done';

  @override
  String categoryCreatedToast(String name) {
    return '\"$name\" category created';
  }

  @override
  String get editCategory => 'Edit Category';

  @override
  String get save => 'Save';

  @override
  String categoryUpdatedToast(String name) {
    return '\"$name\" category updated';
  }

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete \"$name\"? This can\'t be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String categoryDeletedToast(String name) {
    return '\"$name\" category deleted';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String deleteCategoriesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count categories? This can\'t be undone.',
      one: 'Delete this category? This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String categoriesDeletedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories deleted',
      one: 'Category deleted',
    );
    return '$_temp0';
  }

  @override
  String get security => 'Security';

  @override
  String get biometricUnlock => 'Fingerprint Unlock';

  @override
  String get faceIdUnlock => 'Face ID Unlock';

  @override
  String get touchIdUnlock => 'Touch ID Unlock';

  @override
  String get biometricUnlockGeneric => 'Biometric Unlock';

  @override
  String get biometricUnlockSubtitle =>
      'Require your fingerprint or face to open the app';

  @override
  String get biometricUnavailable =>
      'Biometric authentication isn\'t set up on this device';

  @override
  String get biometricAuthFailed => 'Authentication failed';

  @override
  String get biometricPromptReason => 'Authenticate to continue';

  @override
  String get support => 'Support';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get shareAppMessage =>
      'Check out Mantic Document Organizer — scan, organize, and find every important document in seconds.';

  @override
  String get appLocked => 'App Locked';

  @override
  String get unlockToContinue => 'Authenticate to continue';

  @override
  String get unlock => 'Unlock';

  @override
  String get addDocumentTitle => 'Add Document';

  @override
  String get documentTitleLabel => 'Title';

  @override
  String get documentTitleHint => 'e.g. Passport Scan';

  @override
  String get documentTitleRequired => 'Title is required';

  @override
  String get categoryLabel => 'Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Add a tag';

  @override
  String get markAsFavorite => 'Mark as Favorite';

  @override
  String get attachments => 'Attachments';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get files => 'Files';

  @override
  String documentCreatedToast(String name) {
    return '\"$name\" added';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String comingSoonToast(String name) {
    return '$name — coming soon';
  }

  @override
  String get pageNotFound => 'Page not found';

  @override
  String pageNotFoundSubtitle(String path) {
    return 'We couldn\'t find \"$path\".';
  }

  @override
  String get goBack => 'Go back';
}
