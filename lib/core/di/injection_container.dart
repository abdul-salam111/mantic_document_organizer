import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/categories/presentation/add_category/viewmodel/add_category_viewmodel.dart';
import '../localization/localization_exports.dart';
import '../networks/networks_exports.dart';
import '../security/security_exports.dart';
import '../theme/theme_exports.dart';
import '../../features/auth/auth_exports.dart';

import '../../features/home/home_exports.dart';
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

// GENERATED_IMPORTS_START

// GENERATED_IMPORTS_END

final sl = GetIt.instance;

Future<void> setupLocator() async {
  await coreDependencies();

  await authDependencies();
  await homeDependencies();
  await searchDependencies();
  await favoritesDependencies();
  await profileDependencies();
  await documentsDependencies();
  await addDocumentDependencies();
  await navbarDependencies();
  await onboardingDependencies();
  await splashDependencies();
  await settingsDependencies();
  await addCategoryDependencies();
  await manageCategoriesDependencies();
  await categoryDocumentsDependencies();
  // GENERATED_SETUP_CALLS_START

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
}

/// Auth Feature Dependencies
Future<void> authDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteAuthDataSource>(
    () => RemoteAuthDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<SigninUsecase>(
    () => SigninUsecase(repository: sl()),
  );
  sl.registerLazySingleton<SignupUsecase>(
    () => SignupUsecase(repository: sl()),
  );

  // provider
  sl.registerFactory<SigninViewModel>(
    () => SigninViewModel(signinUsecase: sl()),
  );
  sl.registerFactory<SignupViewModel>(
    () => SignupViewModel(signupUsecase: sl()),
  );
}

/// Home Feature Dependencies
Future<void> homeDependencies() async {
  sl.registerLazySingleton<CategoryLocalStore>(() => CategoryLocalStore());
  sl.registerLazySingleton<DocumentLocalStore>(() => DocumentLocalStore());
  sl.registerFactory<HomeViewModel>(
    () => HomeViewModel(categoryStore: sl(), documentStore: sl()),
  );
}

/// Search Feature Dependencies
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
    () => SearchViewModel(searchUsecase: sl()),
  );
}

/// Favorites Feature Dependencies
Future<void> favoritesDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteFavoritesDataSource>(
    () => RemoteFavoritesDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<IFavoritesRepository>(
    () => FavoritesRepositoryImpl(dataSource: sl()),
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

/// Profile Feature Dependencies
Future<void> profileDependencies() async {
  sl.registerFactory<ProfileViewModel>(() => ProfileViewModel());
}

/// Documents Feature Dependencies
///
/// The DataSource/Repository/UseCase below are the original brick-
/// scaffolded REST plumbing (unused for now — see CLAUDE.md's "Known
/// mismatches" section) and stay registered/untouched for whenever a
/// real sqflite repository replaces them. Shared by every page under
/// lib/features/documents/ (add_document, category_documents, ...) —
/// registered once here rather than once per page — since each page's
/// ViewModel writes straight into the shared local stores instead of
/// actually calling this REST layer.
Future<void> documentsDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteDocumentDataSource>(
    () => RemoteDocumentDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<IDocumentRepository>(
    () => DocumentRepositoryImpl(dataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<DocumentUsecase>(
    () => DocumentUsecase(repository: sl()),
  );
}

/// Add Document Page Dependencies
Future<void> addDocumentDependencies() async {
  sl.registerFactory<AddDocumentViewModel>(
    () => AddDocumentViewModel(categoryStore: sl(), documentStore: sl()),
  );
}

/// Navbar Feature Dependencies
Future<void> navbarDependencies() async {
  sl.registerFactory<NavbarViewModel>(() => NavbarViewModel());
}

/// Onboarding Feature Dependencies
Future<void> onboardingDependencies() async {
  sl.registerFactory<OnboardingViewModel>(() => OnboardingViewModel());
}

/// Splash Feature Dependencies
Future<void> splashDependencies() async {
  sl.registerFactory<SplashViewModel>(() => SplashViewModel(sl()));
}

/// Settings Feature Dependencies
Future<void> settingsDependencies() async {
  sl.registerFactory<SettingsViewModel>(() => SettingsViewModel());
}

/// Add Category Feature Dependencies
Future<void> addCategoryDependencies() async {
  sl.registerFactory<AddCategoryViewModel>(
    () => AddCategoryViewModel(categoryStore: sl()),
  );
}

/// Manage Categories Feature Dependencies
Future<void> manageCategoriesDependencies() async {
  sl.registerFactory<ManageCategoriesViewModel>(
    () => ManageCategoriesViewModel(categoryStore: sl()),
  );
}

/// Category Documents Page Dependencies
Future<void> categoryDocumentsDependencies() async {
  sl.registerFactory<CategoryDocumentsViewModel>(
    () => CategoryDocumentsViewModel(documentStore: sl()),
  );
}

// GENERATED_DEPENDENCIES_END
