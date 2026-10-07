import '../../features/documents/data/repository_impl/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/favorites/data/repository_impl/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/favorites_usecase.dart';
import '../../features/home/viewmodel/home_viewmodel.dart';
import '../../features/documents/data/datasources/attachment_local_datasource.dart';
import '../../features/documents/data/repository_impl/document_processing_repository_impl.dart';
import '../../features/documents/domain/repositories/document_processing_repository.dart';
import '../../features/documents/domain/usecases/document_processing_usecases.dart';
import '../../features/categories/data/datasources/category_local_datasource.dart';
import '../../features/categories/data/repository_impl/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/documents/data/datasources/document_local_datasource.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../features/categories/presentation/add_category/viewmodel/add_category_viewmodel.dart';
import '../ai/ai_exports.dart';
import '../database/database_exports.dart';
import '../gallery/gallery_saver_service.dart';
import '../localization/localization_exports.dart';
import '../networks/networks_exports.dart';
import '../notifications/notifications_exports.dart';
import '../ocr/ocr_exports.dart';
import '../sharing/sharing_exports.dart';
import '../security/security_exports.dart';
import '../theme/theme_exports.dart';
import '../../features/auth/auth_exports.dart';
import '../../features/backup/backup_exports.dart';
import '../../features/backup/data/services/document_sync_service.dart';

import '../../features/categories/presentation/manage_categories/manage_categories_exports.dart';
import '../../features/search/search_exports.dart';
import '../../features/favorites/favorites_exports.dart';
import '../../features/profile/profile_exports.dart';
import '../../features/documents/presentation/add_document/add_document_exports.dart';
import '../../features/navbar/navbar_exports.dart';
import '../../features/onboarding/onboarding_exports.dart';
import '../../features/settings/settings_exports.dart';
import '../../features/splash/splash_exports.dart';
import '../../features/documents/presentation/category_documents/category_documents_exports.dart';
import '../../features/documents/presentation/document_viewer/document_viewer_exports.dart';
import '../../features/documents/presentation/trash/trash_exports.dart';
import '../../features/documents/presentation/expiring_soon/expiring_soon_exports.dart';
import 'dart:io';

import '../../features/bulk_import/bulk_import_exports.dart';
import '../../features/bulk_import/data/bulk_import_local_datasource.dart';
import '../../features/bulk_import/data/discovery_examined_assets_store.dart';
import '../../features/bulk_import/data/discovery_watermark_store.dart';
import '../../features/bulk_import/data/file_system_discovery_datasource.dart';
import '../../features/bulk_import/data/gallery_discovery_datasource.dart';
import '../../features/bulk_import/domain/usecases/bulk_import_usecases.dart';
import '../../features/bulk_import/domain/usecases/gallery_discovery_usecases.dart';
import '../background/auto_import_service.dart';
import '../background/document_sync_background_service.dart';
import '../local_storage/local_storage_exports.dart';

// GENERATED_IMPORTS_START

import '../../features/ai_assistant/ai_assistant_exports.dart';

// GENERATED_IMPORTS_END

final sl = GetIt.instance;

Future<void> setupLocator() async {
  await coreDependencies();

  await authDependencies();
  await backupDependencies();
  await documentStorageDependencies();
  await homeDependencies();
  await searchDependencies();
  await favoritesDependencies();
  await profileDependencies();
  await addDocumentDependencies();
  await navbarDependencies();
  await onboardingDependencies();
  await splashDependencies();
  await settingsDependencies();
  await addCategoryDependencies();
  await manageCategoriesDependencies();
  await categoryDocumentsDependencies();
  await documentViewerDependencies();
  await trashDependencies();
  await expiringSoonDependencies();
  await bulkImportDependencies();
  // GENERATED_SETUP_CALLS_START

  await aiAssistantDependencies();
  // GENERATED_SETUP_CALLS_END
}

Future<void> coreDependencies() async {
  sl.registerLazySingleton<Dio>(() => getDio());
  sl.registerLazySingleton(
    () => DioHelper(sl()),
    dispose: (dioHelper) => dioHelper.dispose(),
  );
  sl.registerLazySingleton(() => ThemeController());
  sl.registerLazySingleton(() => LocaleController());
  sl.registerLazySingleton(() => SecurityController());
  sl.registerLazySingleton(() => NetworkPreferenceController());
  sl.registerLazySingleton(
    () => OcrService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton(() => AiDocumentService(sl()));
  sl.registerLazySingleton(() => AiChatService(sl()));
  sl.registerLazySingleton(() => AppDatabase());
  sl.registerLazySingleton(() => AppNotificationPlugin());
  sl.registerLazySingleton(
    () => ExpiryNotificationService(sl()),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton(
    () => AutoImportNotifications(sl()),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton(
    () => AutoImportService(
      createViewModel: () => sl<BulkImportViewModel>(),
      notifications: sl(),
    ),
  );
  sl.registerLazySingleton(() => ShareIntentService());
  sl.registerLazySingleton(() => DirectShareService());
  sl.registerLazySingleton(() => GallerySaverService());
}

Future<void> authDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteAuthDataSource>(
    () => RemoteAuthDataSourceImpl(dioHelper: sl()),
  );
  sl.registerLazySingleton<ISocialIdentityDataSource>(
    () => SocialIdentityDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl(), socialIdentityDataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<SigninUsecase>(
    () => SigninUsecase(repository: sl()),
  );
  sl.registerLazySingleton<SignupUsecase>(
    () => SignupUsecase(repository: sl()),
  );
  sl.registerLazySingleton<SignoutUsecase>(
    () => SignoutUsecase(repository: sl()),
  );
  sl.registerLazySingleton<SocialSigninUsecase>(
    () => SocialSigninUsecase(repository: sl()),
  );
  sl.registerLazySingleton<VerifyEmailUsecase>(
    () => VerifyEmailUsecase(repository: sl()),
  );
  sl.registerLazySingleton<ResendVerificationEmailUsecase>(
    () => ResendVerificationEmailUsecase(repository: sl()),
  );

  // provider
  sl.registerFactory<SigninViewModel>(
    () => SigninViewModel(signinUsecase: sl(), socialSigninUsecase: sl()),
  );
  sl.registerFactory<SignupViewModel>(
    () => SignupViewModel(signupUsecase: sl(), socialSigninUsecase: sl()),
  );
  sl.registerFactory<EmailVerificationViewModel>(
    () => EmailVerificationViewModel(
      verifyEmailUsecase: sl(),
      resendVerificationEmailUsecase: sl(),
    ),
  );
}

Future<void> backupDependencies() async {
  sl.registerLazySingleton(() => DocumentSyncService(sl(), sl()));
  sl.registerLazySingleton<IBackupRemoteDataSource>(
    () => BackupRemoteDataSourceImpl(dioHelper: sl()),
  );
  sl.registerLazySingleton<IBackupRepository>(
    () => BackupRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => PrepareBackupUsecase(sl()));
  sl.registerLazySingleton(() => ConnectGoogleDriveUsecase(sl()));
  sl.registerLazySingleton(
    () => DocumentSyncNotifications(sl()),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton(
    () => DocumentSyncBackgroundService(
      syncService: sl(),
      database: sl(),
      documents: sl(),
      notifications: sl(),
    ),
  );
}

Future<void> documentStorageDependencies() async {
  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => SqliteCategoryDataSource(sl()),
  );
  sl.registerLazySingleton<ICategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryUseCases>(() => CategoryUseCases(sl()));
  sl.registerLazySingleton<DocumentLocalDataSource>(
    () => SqliteDocumentDataSource(sl()),
  );
  sl.registerLazySingleton<IDocumentRepository>(
    () => DocumentRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<DocumentUseCases>(() => DocumentUseCases(sl()));
}

Future<void> homeDependencies() async {
  sl.registerFactory<HomeViewModel>(
    () => HomeViewModel(categoryUseCases: sl(), documentUseCases: sl()),
  );
}

Future<void> searchDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteSearchDataSource>(
    () => RemoteSearchDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<ISearchRepository>(
    () => SearchRepositoryImpl(dataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<SearchUsecase>(
    () => SearchUsecase(repository: sl()),
  );

  // ViewModel
  sl.registerFactory<SearchViewModel>(
    () => SearchViewModel(categoryUseCases: sl(), documentUseCases: sl()),
  );
}

Future<void> favoritesDependencies() async {
  // Repository
  sl.registerLazySingleton<IFavoritesRepository>(
    () => FavoritesRepositoryImpl(sl()),
  );

  // UseCase
  sl.registerLazySingleton<FavoritesUsecase>(
    () => FavoritesUsecase(repository: sl()),
  );

  // ViewModel
  sl.registerFactory<FavoritesViewModel>(
    () => FavoritesViewModel(favoritesUsecase: sl()),
  );
}

Future<void> profileDependencies() async {
  sl.registerFactory<ProfileViewModel>(
    () => ProfileViewModel(
      categoryUseCases: sl(),
      documentUseCases: sl(),
      signoutUsecase: sl(),
    ),
  );
}

Future<void> addDocumentDependencies() async {
  sl.registerLazySingleton<AttachmentLocalDataSource>(
    () => DeviceAttachmentDataSource(),
  );
  sl.registerLazySingleton<IDocumentProcessingRepository>(
    () => DocumentProcessingRepositoryImpl(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => DocumentProcessingUseCases(sl()));
  sl.registerFactory<AddDocumentViewModel>(
    () => AddDocumentViewModel(
      categoryUseCases: sl(),
      documentUseCases: sl(),
      processing: sl(),
    ),
  );
}

Future<void> navbarDependencies() async {
  sl.registerFactory<NavbarViewModel>(() => NavbarViewModel());
}

Future<void> onboardingDependencies() async {
  sl.registerFactory<OnboardingViewModel>(() => OnboardingViewModel());
}

Future<void> bulkImportDependencies() async {
  await BulkImportLocalDataSource.cleanupStaleSessions();
  sl.registerFactory<BulkImportViewModel>(
    () => BulkImportViewModel(
      imports: BulkImportUseCases(BulkImportLocalDataSource()),
      categories: sl(),
      documents: sl(),
      processing: sl(),
      discovery: GalleryDiscoveryUseCases(GalleryDiscoveryDataSource()),
      watermark: DiscoveryWatermarkStore(),
      examinedAssets: DiscoveryExaminedAssetsStore(
        database: sl(),
        source: DiscoveryExaminedAssetsStore.gallerySource,
      ),
      // Same connectivity check DioHelper already uses -- discovery is now
      // AI-driven and cannot work offline at all.
      checkConnectivity: () => InternetConnectionChecker.instance.hasConnection,
      // Android-only broader-than-gallery source (Downloads/Documents) --
      // requires MANAGE_EXTERNAL_STORAGE, which iOS has no equivalent of.
      fileSystemDiscovery: Platform.isAndroid
          ? GalleryDiscoveryUseCases(FileSystemDiscoveryDataSource())
          : null,
      fileSystemWatermark: Platform.isAndroid
          ? DiscoveryWatermarkStore(
              storageKey: StorageKeys.autoImportFileSystemWatermark,
            )
          : null,
      fileSystemExaminedAssets: Platform.isAndroid
          ? DiscoveryExaminedAssetsStore(
              database: sl(),
              source: DiscoveryExaminedAssetsStore.fileSystemSource,
            )
          : null,
    ),
  );
}

Future<void> splashDependencies() async {
  sl.registerFactory<SplashViewModel>(() => SplashViewModel(sl()));
}

Future<void> settingsDependencies() async {
  sl.registerFactory<SettingsViewModel>(() => SettingsViewModel());
}

Future<void> addCategoryDependencies() async {
  sl.registerFactory<AddCategoryViewModel>(
    () => AddCategoryViewModel(categoryUseCases: sl()),
  );
}

Future<void> manageCategoriesDependencies() async {
  sl.registerFactory<ManageCategoriesViewModel>(
    () => ManageCategoriesViewModel(
      categoryUseCases: sl(),
      documentUseCases: sl(),
    ),
  );
}

Future<void> categoryDocumentsDependencies() async {
  sl.registerFactory<CategoryDocumentsViewModel>(
    () => CategoryDocumentsViewModel(documentUseCases: sl()),
  );
}

Future<void> documentViewerDependencies() async {
  sl.registerFactory<DocumentViewerViewModel>(
    () => DocumentViewerViewModel(
      documentUseCases: sl(),
      categoryUseCases: sl(),
      processing: sl(),
    ),
  );
}

Future<void> trashDependencies() async {
  sl.registerFactory<TrashViewModel>(
    () => TrashViewModel(documentUseCases: sl()),
  );
}

Future<void> expiringSoonDependencies() async {
  sl.registerFactory<ExpiringSoonViewModel>(
    () => ExpiringSoonViewModel(documentUseCases: sl()),
  );
}

Future<void> aiAssistantDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteAiAssistantDataSource>(
    () => RemoteAiAssistantDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<IAiAssistantRepository>(
    () => AiAssistantRepositoryImpl(dataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<AiAssistantUsecase>(
    () => AiAssistantUsecase(repository: sl()),
  );

  // ViewModel — a session-lived singleton (not registerFactory), so
  // navigating away from and back into the AI Assistant screen keeps the
  // running conversation instead of starting a fresh one every time.
  sl.registerLazySingleton<AiAssistantViewModel>(
    () => AiAssistantViewModel(documentUseCases: sl(), aiChatService: sl()),
  );
}

// GENERATED_DEPENDENCIES_END
