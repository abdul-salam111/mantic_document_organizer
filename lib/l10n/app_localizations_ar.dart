// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get splashTagline => 'منظّم المستندات';

  @override
  String get onboardingHeadline => 'جميع مستنداتك،\nمنظَّمة بشكل رائع';

  @override
  String get onboardingSubtitle =>
      'امسح مستنداتك ضوئيًا، صنّفها، واعثر على أي مستند مهم خلال ثوانٍ — كل ذلك مخزَّن بأمان على جهازك، حتى بدون اتصال بالإنترنت.';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingNoSignIn =>
      'لا حاجة لتسجيل الدخول — تبقى مستنداتك على هذا الجهاز فقط.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navAllDocs => 'المستندات';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get homeSearchHint => 'ابحث عن الفئات والمستندات';

  @override
  String get recentFiles => 'الملفات الأخيرة';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get categories => 'الفئات';

  @override
  String get uncategorized => 'بدون تصنيف';

  @override
  String get newCategory => 'فئة جديدة';

  @override
  String fileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات',
      one: '$count ملف',
    );
    return '$_temp0';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: '$count نتيجة',
    );
    return '$_temp0';
  }

  @override
  String get profileTooltip => 'الملف الشخصي';

  @override
  String get allDocsTitle => 'المستندات';

  @override
  String get allDocsSearchHint => 'ابحث عن مستندات أو فئات';

  @override
  String get allCategoryTab => 'الكل';

  @override
  String get noDocumentsFound => 'لم يتم العثور على مستندات';

  @override
  String nothingInCategoryYet(String category) {
    return 'لا يوجد شيء في \"$category\" بعد';
  }

  @override
  String nothingMatchesQueryInCategory(String query, String category) {
    return 'لا يوجد ما يطابق \"$query\" في \"$category\"';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'لا يوجد ما يطابق \"$query\"';
  }

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get noFavoritesYet => 'لا توجد عناصر مفضلة بعد';

  @override
  String get favoritesEmptySubtitle =>
      'ستظهر هنا المستندات التي تضيفها إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get guest => 'ضيف';

  @override
  String get account => 'الحساب';

  @override
  String get localOnlyStatus => 'محلي فقط — تبقى مستنداتك على هذا الجهاز';

  @override
  String get setUpBackup => 'إعداد النسخ الاحتياطي';

  @override
  String get trash => 'سلة المهملات';

  @override
  String get trashSubtitle => 'استعادة المستندات المحذوفة مؤخرًا';

  @override
  String get settingsSubtitle => 'المظهر واللغة والفئات والأمان';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get statDocuments => 'المستندات';

  @override
  String get statCategories => 'الفئات';

  @override
  String get statFavorites => 'المفضلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get manageCategories => 'إدارة الفئات';

  @override
  String get searchCategories => 'ابحث عن الفئات';

  @override
  String get noCategoriesFound => 'لم يتم العثور على فئات';

  @override
  String get categoryNameLabel => 'اسم الفئة';

  @override
  String get categoryNameHint => 'مثال: كشوف الحساب البنكي';

  @override
  String get categoryNameRequired => 'اسم الفئة مطلوب';

  @override
  String get categoryNameTaken => 'هذه الفئة موجودة بالفعل';

  @override
  String get chooseIcon => 'اختر أيقونة';

  @override
  String get searchIcons => 'ابحث عن الأيقونات';

  @override
  String get noIconsFound => 'لم يتم العثور على أيقونات';

  @override
  String get chooseColor => 'اختر لونًا';

  @override
  String get create => 'إنشاء';

  @override
  String get done => 'تم';

  @override
  String categoryCreatedToast(String name) {
    return 'تم إنشاء فئة \"$name\"';
  }

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get save => 'حفظ';

  @override
  String categoryUpdatedToast(String name) {
    return 'تم تحديث فئة \"$name\"';
  }

  @override
  String get deleteCategory => 'حذف الفئة';

  @override
  String deleteCategoryConfirm(String name) {
    return 'حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get delete => 'حذف';

  @override
  String categoryDeletedToast(String name) {
    return 'تم حذف فئة \"$name\"';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count',
      one: 'تم تحديد $count',
    );
    return '$_temp0';
  }

  @override
  String deleteCategoriesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حذف $count فئات؟ لا يمكن التراجع عن هذا الإجراء.',
      one: 'حذف هذه الفئة؟ لا يمكن التراجع عن هذا الإجراء.',
    );
    return '$_temp0';
  }

  @override
  String categoriesDeletedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم حذف $count فئات',
      one: 'تم حذف الفئة',
    );
    return '$_temp0';
  }

  @override
  String get security => 'الأمان';

  @override
  String get biometricUnlock => 'فتح القفل بالبصمة';

  @override
  String get faceIdUnlock => 'فتح القفل عبر Face ID';

  @override
  String get touchIdUnlock => 'فتح القفل عبر Touch ID';

  @override
  String get biometricUnlockGeneric => 'فتح القفل البيومتري';

  @override
  String get biometricUnlockSubtitle => 'يتطلب بصمتك أو وجهك لفتح التطبيق';

  @override
  String get biometricUnavailable =>
      'المصادقة البيومترية غير مُعدّة على هذا الجهاز';

  @override
  String get biometricAuthFailed => 'فشلت المصادقة';

  @override
  String get biometricPromptReason => 'صادِق للمتابعة';

  @override
  String get support => 'الدعم';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String get shareApp => 'مشاركة التطبيق';

  @override
  String get shareAppMessage =>
      'تعرّف على Mantic Document Organizer — امسح مستنداتك ضوئيًا، نظّمها، واعثر على أي مستند مهم خلال ثوانٍ.';

  @override
  String get appLocked => 'التطبيق مُقفل';

  @override
  String get unlockToContinue => 'صادِق للمتابعة';

  @override
  String get unlock => 'فتح القفل';

  @override
  String get addDocumentTitle => 'إضافة مستند';

  @override
  String get editDocumentTitle => 'تعديل الملف';

  @override
  String get documentTitleLabel => 'العنوان';

  @override
  String get documentTitleHint => 'مثال: مسح جواز السفر';

  @override
  String get documentTitleRequired => 'العنوان مطلوب';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get tags => 'الوسوم';

  @override
  String get tagsHint => 'مثال: فاتورة-2026';

  @override
  String tagsHelper(int maxLength) {
    return 'أحرف وأرقام و- و_ فقط، بحد أقصى $maxLength حرفًا لكل وسم';
  }

  @override
  String tagErrorLimitReached(int maxCount) {
    return 'يمكنك إضافة حتى $maxCount وسوم';
  }

  @override
  String tagErrorTooLong(int maxLength) {
    return 'يجب ألا يتجاوز الوسم $maxLength حرفًا';
  }

  @override
  String get tagErrorInvalidCharacters =>
      'استخدم الأحرف والأرقام و- و_ فقط (بدون مسافات)';

  @override
  String get tagErrorDuplicate => 'تمت إضافة هذا الوسم بالفعل';

  @override
  String get documentExpirable => 'هذا المستند قابل لانتهاء الصلاحية';

  @override
  String expiresOn(String date) {
    return 'تنتهي الصلاحية في $date';
  }

  @override
  String get tapToSetExpiryDate => 'اضغط لتحديد تاريخ ووقت انتهاء الصلاحية';

  @override
  String get attachments => 'المرفقات';

  @override
  String get extractingTextStatus => 'استخراج النص…';

  @override
  String get organizingWithAiStatus => 'التنظيم باستخدام الذكاء الاصطناعي…';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get files => 'الملفات';

  @override
  String get filesImagesNotAllowed =>
      'الصور غير مقبولة هنا — استخدم الكاميرا أو المعرض';

  @override
  String get scanFailedToast => 'فشل المسح — يرجى المحاولة مرة أخرى';

  @override
  String documentCreatedToast(String name) {
    return 'تمت إضافة \"$name\"';
  }

  @override
  String documentUpdatedToast(String name) {
    return 'تم تحديث \"$name\"';
  }

  @override
  String get searchDocumentsHint => 'ابحث عن المستندات';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortNewestFirst => 'الأحدث أولاً';

  @override
  String get sortOldestFirst => 'الأقدم أولاً';

  @override
  String get sortNameAZ => 'الاسم (أ-ي)';

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get share => 'مشاركة';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get move => 'نقل';

  @override
  String get renameDocument => 'إعادة تسمية المستند';

  @override
  String documentRenamedToast(String name) {
    return 'أُعيدت التسمية إلى \"$name\"';
  }

  @override
  String documentMovedToast(String category) {
    return 'تم النقل إلى \"$category\"';
  }

  @override
  String get deleteDocument => 'حذف المستند';

  @override
  String deleteDocumentConfirm(String name) {
    return 'حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String documentDeletedToast(String name) {
    return 'تم حذف \"$name\"';
  }

  @override
  String get noPreviewAvailable => 'المعاينة غير متاحة لهذا النوع من الملفات';

  @override
  String addedOn(String date) {
    return 'أُضيف في $date';
  }

  @override
  String get comingSoon => 'قريبًا';

  @override
  String comingSoonToast(String name) {
    return '$name — قريبًا';
  }

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String pageNotFoundSubtitle(String path) {
    return 'تعذّر العثور على \"$path\".';
  }

  @override
  String get goBack => 'رجوع';
}
