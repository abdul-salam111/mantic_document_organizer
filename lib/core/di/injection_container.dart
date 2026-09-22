import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../networks/networks_exports.dart';
import '../theme/theme_exports.dart';
import '../../features/auth/auth_exports.dart';
import '../../features/home/home_exports.dart';
import '../../features/search/search_exports.dart';
import '../../features/favorites/favorites_exports.dart';
import '../../features/profile/profile_exports.dart';
import '../../features/add_document/add_document_exports.dart';
import '../../features/navbar/navbar_exports.dart';
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
  await addDocumentDependencies();
  await navbarDependencies();
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
  sl.registerFactory<HomeViewModel>(() => HomeViewModel());
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

/// Add Document Feature Dependencies
Future<void> addDocumentDependencies() async {
  // DataSource
  sl.registerLazySingleton<IRemoteAddDocumentDataSource>(
    () => RemoteAddDocumentDataSourceImpl(dioHelper: sl()),
  );

  // Repository
  sl.registerLazySingleton<IAddDocumentRepository>(
    () => AddDocumentRepositoryImpl(dataSource: sl()),
  );

  // UseCase
  sl.registerLazySingleton<AddDocumentUsecase>(
    () => AddDocumentUsecase(repository: sl()),
  );

  // ViewModel
  sl.registerFactory<AddDocumentViewModel>(
    () => AddDocumentViewModel(addDocumentUsecase: sl()),
  );
}

/// Navbar Feature Dependencies
Future<void> navbarDependencies() async {
  sl.registerFactory<NavbarViewModel>(() => NavbarViewModel());
}

// GENERATED_DEPENDENCIES_END
