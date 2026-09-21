import 'dart:io';
import 'dart:convert';
import 'package:mason/mason.dart';

// Scaffolds a single, fixed "auth" example feature (Clean Architecture +
// Provider + GetIt + GoRouter) into lib/. This is meant for a brand-new/
// empty project that doesn't already have this structure — it is NOT a
// general architecture generator, and it does not take a feature name
// (see create_feature for that). Running it against a project that already
// has lib/features/auth, core/di, or lib/routes will overwrite those
// files with this brick's hardcoded versions.
//
// "auth" is the module: data/ and domain/ are shared across every auth
// sub-flow (signin today, signup/forgot-password/etc. later).
// presentation/ is split one folder per sub-flow (presentation/signin/,
// later presentation/signup/), each with its own views/ and viewmodels/,
// since those are the only parts that don't overlap between sub-flows.
Future<void> run(HookContext context) async {
  final logger = context.logger;

  final currentDir = Directory.current;
  final libDir = Directory('${currentDir.path}/lib');
  _warnIfOverwriting(libDir, logger);

  logger.info('🔧 Scaffolding the example "auth" feature...');
  await _installProviderDependencies(logger);
  if (!libDir.existsSync()) {
    libDir.createSync(recursive: true);
  }

  _createCleanFeature(libDir, logger);

  logger.success('✅ Example auth feature scaffolded!');

  logger.info('''
📦 Provider, GetIt, and GoRouter packages have been added to your pubspec.yaml.
💡 To add further features, use "mason make create_feature" instead — this
   brick only ever recreates the fixed auth example.
''');
}

/// This hook writes files directly via `dart:io` (not mason's own
/// `__brick__` templating), so mason's `--on-conflict` prompt never sees
/// these overwrites coming — the only way a developer running this against
/// a project that already has an `auth` feature and DI wiring finds out is
/// this loud, explicit warning up front, listing exactly what's about to be
/// clobbered.
void _warnIfOverwriting(Directory libDir, Logger logger) {
  final atRisk = <String>[
    'lib/features/auth',
    'lib/routes/route_names.dart',
    'lib/routes/route_paths.dart',
    'lib/routes/app_router.dart',
    'lib/routes/routes_exports.dart',
    'lib/core/di/injection_container.dart',
  ];

  final existing = atRisk.where((path) {
    final relative = path.substring('lib/'.length);
    final entity = FileSystemEntity.typeSync('${libDir.path}/$relative');
    return entity != FileSystemEntityType.notFound;
  }).toList();

  if (existing.isEmpty) return;

  logger.warn(
    '⚠️  This will OVERWRITE the following existing file(s)/folder(s) with '
    "this brick's hardcoded auth example, discarding whatever is there now:",
  );
  for (final path in existing) {
    logger.warn('   - $path');
  }
  logger.warn(
    'Back up or commit any custom changes to these first if you need them.',
  );
}

Future<void> _installProviderDependencies(Logger logger) async {
  logger.info('📦 Installing Provider packages...');

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    logger.err('❌ pubspec.yaml not found in current directory.');
    return;
  }

  String content = await pubspecFile.readAsString();

  bool hasProvider = false;
  bool hasGetIt = false;
  bool hasGoRouter = false;

  final lines = content.split('\n');
  bool inDependenciesSection = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    if (line == 'dependencies:') {
      inDependenciesSection = true;
      continue;
    }

    if (line == 'dev_dependencies:' ||
        (line.isNotEmpty &&
            !lines[i].startsWith('  ') &&
            !lines[i].startsWith('\t') &&
            inDependenciesSection)) {
      inDependenciesSection = false;
    }

    if (inDependenciesSection) {
      if (line.contains('provider:')) hasProvider = true;
      if (line.contains('get_it:')) hasGetIt = true;
      if (line.contains('go_router:')) hasGoRouter = true;
    }
  }

  // Keep these in lockstep with the root pubspec.yaml's provider/get_it/
  // go_router versions — this brick has no automated check against drift,
  // so bumping one without the other will silently pull an incompatible
  // major version into a project already using the template's DI/router code.
  final packagesToAdd = <String>[];
  if (!hasProvider) packagesToAdd.add('  provider: ^6.1.5+1');
  if (!hasGetIt) packagesToAdd.add('  get_it: ^9.2.0');
  if (!hasGoRouter) packagesToAdd.add('  go_router: ^17.0.1');

  if (packagesToAdd.isEmpty) {
    logger.info('✅ All required packages are already installed');
    return;
  }

  logger.info('📦 Adding missing packages: ${packagesToAdd.length} package(s)');

  final backupFile = File('pubspec.yaml.backup');
  await backupFile.writeAsString(content);
  logger.info('📋 Created backup: pubspec.yaml.backup');

  final updatedLines = <String>[];
  inDependenciesSection = false;
  bool packagesAdded = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    updatedLines.add(line);

    final trimmedLine = line.trim();

    if (trimmedLine == 'dependencies:') {
      inDependenciesSection = true;
      continue;
    }

    if (inDependenciesSection && !packagesAdded) {
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        final trimmedNextLine = nextLine.trim();

        if (trimmedNextLine == 'dev_dependencies:' ||
            (trimmedNextLine.isNotEmpty &&
                !nextLine.startsWith('  ') &&
                !nextLine.startsWith('\t'))) {
          for (final package in packagesToAdd) {
            updatedLines.add(package);
          }
          packagesAdded = true;
        }
      } else {
        for (final package in packagesToAdd) {
          updatedLines.add(package);
        }
        packagesAdded = true;
      }
    }
  }

  final updatedContent = updatedLines.join('\n');
  await pubspecFile.writeAsString(updatedContent);
  logger.success('✅ Added packages to pubspec.yaml');

  for (final package in packagesToAdd) {
    logger.info('   + $package');
  }

  logger.info('\n🔄 Running flutter pub get...');
  try {
    final process =
        await Process.start('flutter', ['pub', 'get'], runInShell: true);

    process.stdout.transform(utf8.decoder).listen((data) {
      final output = data.trim();
      if (output.isNotEmpty) {
        logger.info(output);
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      final output = data.trim();
      if (output.isNotEmpty) {
        logger.err(output);
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      logger.success('✅ Dependencies installed successfully');
      if (backupFile.existsSync()) {
        backupFile.deleteSync();
      }
    } else {
      logger.err('❌ Failed to install dependencies');
      logger.warn('⚠️  Restoring original pubspec.yaml from backup...');
      await pubspecFile.writeAsString(content);
      logger.info('Please run "flutter pub get" manually.');
    }
  } catch (e) {
    logger.err('❌ Error running flutter pub get: $e');
    logger.warn('⚠️  Restoring original pubspec.yaml from backup...');
    await pubspecFile.writeAsString(content);
    logger.info('Please run "flutter pub get" manually.');
  }
}

// ------------------------------------------------------------------
// 🧩 CLEAN FEATURE-BASED (with Provider + GetIt + GoRouter)
// ------------------------------------------------------------------
void _createCleanFeature(Directory libDir, Logger logger) {
  final featureName = 'auth';
  final featureDir = Directory('${libDir.path}/features/$featureName');
  final dataFolders = [
    'datasources',
    'repository_impl',
    'models',
    'models/request_models',
    'models/response_models'
  ];
  final domainFolders = ['repositories', 'usecases', 'entities'];
  // presentation/ is split one folder per auth sub-flow — only "signin"
  // exists today; a future "signup" sub-flow would get its own
  // presentation/signup/views + presentation/signup/viewmodels sitting
  // next to this one, still sharing data/ and domain/ above.
  final presentationFolders = [
    'signin/views',
    'signin/viewmodels',
  ];

  // ✅ Create root structure
  for (var folder in [
    'features',
    'features/$featureName',
    'features/$featureName/data',
    'features/$featureName/domain',
    'features/$featureName/presentation',
  ]) {
    Directory('${libDir.path}/$folder').createSync(recursive: true);
    logger.success('📁 Created: lib/$folder');
  }

  // ✅ Create data layer
  for (var folder in dataFolders) {
    Directory('${featureDir.path}/data/$folder').createSync(recursive: true);
    logger.success('📁 Created: lib/features/$featureName/data/$folder');
  }

  // ✅ Create domain layer
  for (var folder in domainFolders) {
    Directory('${featureDir.path}/domain/$folder').createSync(recursive: true);
    logger.success('📁 Created: lib/features/$featureName/domain/$folder');
  }

  // ✅ Create presentation layer
  for (var folder in presentationFolders) {
    Directory('${featureDir.path}/presentation/$folder')
        .createSync(recursive: true);
    logger
        .success('📁 Created: lib/features/$featureName/presentation/$folder');
  }

  // ✅ Create core folders
  _createCoreFolders(libDir, logger);

  // Create Provider files for clean architecture
  _createProviderFiles(featureDir, logger);

  // ✅ Create this feature's own export file
  _createAuthExportsFile(featureDir, logger);

  // ✅ Create routing files
  final className = 'Signin';
  final fileName = 'signin';
  _createRouteFiles(libDir, fileName, className,
      'features/$featureName/presentation/signin/views', logger);

  // ✅ Create dependency injection file
  _createDependencyInjection(libDir, logger);
}

// ------------------------------------------------------------------
// 🧩 Create Core Folders
// ------------------------------------------------------------------
void _createCoreFolders(Directory libDir, Logger logger) {
  // `routes/` lives directly under lib/, as a sibling of core/ — not
  // inside it — so it's listed separately from the actual core/ folders.
  final topLevelFolders = ['routes', 'core/di'];

  for (var folder in topLevelFolders) {
    Directory('${libDir.path}/$folder').createSync(recursive: true);
    logger.success('📁 Created: lib/$folder');
  }
}

// ------------------------------------------------------------------
// 🧩 Create Provider-specific files for Clean Architecture
// ------------------------------------------------------------------
void _createProviderFiles(Directory featureDir, Logger logger) {
  // ✅ Request model (plain — this hook doesn't run build_runner, so it
  // deliberately avoids @freezed/json_serializable here even though the
  // rest of the template uses them; a real feature you build by hand can
  // upgrade to freezed once you're running codegen anyway).
  File('${featureDir.path}/data/models/request_models/login_user.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''class LoginUser {
  final String email;
  final String password;

  LoginUser({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/data/models/request_models/login_user.dart');

  // ✅ Response model (plain) — parses the API's nested "data" object
  // itself, so everything above this file just sees flat fields.
  File('${featureDir.path}/data/models/response_models/user_model.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? token;

  UserModel({this.id, this.name, this.email, this.token});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return UserModel(
      id: data?['id']?.toString(),
      name: data?['name'] as String?,
      email: data?['email'] as String?,
      token: data?['token'] as String?,
    );
  }
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/data/models/response_models/user_model.dart');

  // ✅ Page File (using Provider) — lives under presentation/signin/views/,
  // one level deeper than the shared data/domain layers, so its relative
  // imports back to core/ need an extra "../".
  File('${featureDir.path}/presentation/signin/views/signin_page.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../viewmodels/signin_viewmodel.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SigninViewModel>(),
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validator.validateEmail,
                  ),
                  heightBox(20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: Validator.validatePassword,
                  ),
                  heightBox(20),
                  Consumer<SigninViewModel>(
                    builder: (context, vm, _) {
                      return ElevatedButton(
                        onPressed: vm.isLoading
                            ? null
                            : () {
                                if (!(_formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                vm.signin(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                              },
                        child: vm.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Sign In'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

''');
  logger.success(
      '🧱 Created: lib/features/auth/presentation/signin/views/signin_page.dart');

  // ✅ ViewModel (Provider + UseCaseExecutor) — also under
  // presentation/signin/viewmodels/, same extra nesting as the page above.
  // Persists the signed-in user via `SessionController` (core/services/
  // session_manager.dart), which is pre-shipped core/ code (this brick
  // doesn't touch core/services) and already expects an `AuthEntity`.
  File('${featureDir.path}/presentation/signin/viewmodels/signin_viewmodel.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/login_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signin_usecase.dart';

class SigninViewModel extends ChangeNotifier with UseCaseExecutor {
  final SigninUsecase _signinUsecase;

  SigninViewModel({required SigninUsecase signinUsecase})
    : _signinUsecase = signinUsecase;

  AuthEntity? _user;
  AuthEntity? get user => _user;

  Future<void> signin(String email, String password) async {
    await execute(
      call: () => _signinUsecase(LoginUser(email: email, password: password)),
      onSuccess: (user) async {
        _user = user;
        await SessionController.instance.saveUserInStorage(user);
        await SessionController.instance.loadUserFromStorage();
        AppNavigator.goNamed(RouteNames.signin);
      },
    );
  }
}

''');
  logger.success(
      '🧱 Created: lib/features/auth/presentation/signin/viewmodels/signin_viewmodel.dart');

  // ✅ DataSource (shared across every auth sub-flow)
  File('${featureDir.path}/data/datasources/remote_auth_datasource.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/login_user.dart';
import '../models/response_models/user_model.dart';

abstract interface class IRemoteAuthDataSource {
  Future<UserModel> loginUser({required LoginUser loginUser});
}

class RemoteAuthDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteAuthDataSource {
  RemoteAuthDataSourceImpl({required super.dioHelper});

  @override
  Future<UserModel> loginUser({required LoginUser loginUser}) async {
    return post(
      url: ApiEndPoints.loginByUid,
      parser: (json) => UserModel.fromJson(json),
      body: loginUser.toJson(),
    );
  }
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/data/datasources/remote_auth_datasource.dart');

  // ✅ Entity (shared across every auth sub-flow) — the domain-layer
  // representation of a signed-in user, decoupled from `UserModel`'s API
  // response shape (mapped at the repository boundary below). `toJson`/
  // `fromJson` exist because `SessionController` (pre-shipped core/
  // code) persists this via those.
  File('${featureDir.path}/domain/entities/auth_entity.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''class AuthEntity {
  final String id;
  final String? name;
  final String? email;
  final String? token;

  const AuthEntity({required this.id, this.name, this.email, this.token});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'token': token,
  };

  factory AuthEntity.fromJson(Map<String, dynamic> json) => AuthEntity(
    id: json['id'] as String? ?? '',
    name: json['name'] as String?,
    email: json['email'] as String?,
    token: json['token'] as String?,
  );
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/domain/entities/auth_entity.dart');

  // ✅ UseCase — one file per auth action; this is the signin action.
  // A future signup action would get its own signup_usecase.dart sitting
  // next to this one in the same (shared) domain/usecases/ folder.
  File('${featureDir.path}/domain/usecases/signin_usecase.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/login_user.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class SigninUsecase implements Usecase<AuthEntity, LoginUser> {
  final IAuthRepository repository;

  SigninUsecase({required this.repository});

  @override
  Future<Result<AuthEntity>> call(LoginUser loginUser) {
    return repository.signinUser(loginUser: loginUser);
  }
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/domain/usecases/signin_usecase.dart');

  // ✅ Repository Interface (shared across every auth sub-flow)
  File('${featureDir.path}/domain/repositories/auth_repository.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/login_user.dart';
import '../entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Result<AuthEntity>> signinUser({required LoginUser loginUser});
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/domain/repositories/auth_repository.dart');

  // ✅ Repository Implementation (shared across every auth sub-flow) —
  // maps the data-layer `UserModel` response to the domain `AuthEntity`
  // here, at the boundary, so nothing above this file needs to know
  // about the API's response shape.
  File('${featureDir.path}/data/repository_impl/auth_repository_impl.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_auth_datasource.dart';
import '../models/request_models/login_user.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends BaseRepository implements IAuthRepository {
  final IRemoteAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Result<AuthEntity>> signinUser({required LoginUser loginUser}) async {
    final result = await execute(
      call: () => dataSource.loginUser(loginUser: loginUser),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (model) => Success(
        AuthEntity(
          id: model.id ?? '',
          name: model.name,
          email: model.email,
          token: model.token,
        ),
      ),
    );
  }
}
''');
  logger.success(
      '🧱 Created: lib/features/auth/data/repository_impl/auth_repository_impl.dart');
}

// ------------------------------------------------------------------
// 🧩 Create this feature's export file
// ------------------------------------------------------------------
void _createAuthExportsFile(Directory featureDir, Logger logger) {
  File('${featureDir.path}/auth_exports.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''// Barrel export for the auth feature — this is what OTHER
// features/core files import to reach auth's public API. Files
// *inside* the auth feature should import each other with relative
// paths, not this file.
export 'data/datasources/remote_auth_datasource.dart';
export 'data/models/request_models/login_user.dart';
export 'data/models/response_models/user_model.dart';
export 'data/repository_impl/auth_repository_impl.dart';
export 'domain/entities/auth_entity.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/signin_usecase.dart';
export 'presentation/signin/views/signin_page.dart';
export 'presentation/signin/viewmodels/signin_viewmodel.dart';
''');
  logger.success('🧱 Created: lib/features/auth/auth_exports.dart');
}

// ------------------------------------------------------------------
// 🧩 Create Route Files (GoRouter)
// ------------------------------------------------------------------
void _createRouteFiles(Directory libDir, String fileName, String className,
    String pagePath, Logger logger) {
  final routesDir = Directory('${libDir.path}/routes');

  // ✅ 1. Create route_names.dart
  final namesFile = File('${routesDir.path}/route_names.dart');
  namesFile.writeAsStringSync('''
class RouteNames {
  static const String signin = "signin";

  // GENERATED_ROUTE_NAMES_START
  // GENERATED_ROUTE_NAMES_END
}
''');
  logger.success('🧭 Created: lib/routes/route_names.dart');

  // ✅ 2. Create app_router.dart
  final routerFile = File('${routesDir.path}/app_router.dart');
  routerFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'route_paths.dart';
import '../core/theme/theme_exports.dart';
import '../core/widgets/widgets_exports.dart';
import '../features/auth/auth_exports.dart';
// GENERATED_IMPORTS_START
// GENERATED_IMPORTS_END

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void goNamed(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.goNamed(name, extra: extra);
    }
  }

  static void pushNamed(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.pushNamed(name, extra: extra);
    }
  }

  static void replaceTo(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.replaceNamed(name, extra: extra);
    }
  }

  static void pop() {
    final context = navigatorKey.currentContext;
    if (context != null && context.canPop()) {
      context.pop();
    }
  }
}

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.initialRoute,
    navigatorKey: AppNavigator.navigatorKey,
    errorBuilder: (context, state) => _RouteErrorPage(state: state),
    routes: [
      GoRoute(
        path: RoutePaths.signin,
        name: RouteNames.signin,
        builder: (context, state) => const SigninPage(),
      ),
      // GENERATED_ROUTES_START
      // GENERATED_ROUTES_END
    ],
  );
}

/// Shown for any unmatched route/deep link instead of go_router's default,
/// unstyled error page.
class _RouteErrorPage extends StatelessWidget {
  final GoRouterState state;

  const _RouteErrorPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Page not found', style: context.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  "We couldn't find \\"\${state.uri}\\".",
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Go back',
                  onPressed: () => context.goNamed(RouteNames.signin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''');
  logger.success('🧭 Created: lib/routes/app_router.dart');

  // ✅ 3. Create route_paths.dart
  final pathsFile = File('${routesDir.path}/route_paths.dart');
  pathsFile.writeAsStringSync('''
class RoutePaths {
  static const String initialRoute = signin;
  static const String signin = "/signin";

  // GENERATED_ROUTE_PATHS_START
  // GENERATED_ROUTE_PATHS_END
}
''');
  logger.success('🧭 Created: lib/routes/route_paths.dart');

  // ✅ 4. Create routes_exports.dart
  final exportsFile = File('${routesDir.path}/routes_exports.dart');
  exportsFile.writeAsStringSync('''// Barrel export for lib/routes — import this to get AppRoutes,
// AppNavigator, RouteNames, RoutePaths, and the go_router package.
export 'package:go_router/go_router.dart';

export 'app_router.dart';
export 'route_names.dart';
export 'route_paths.dart';
''');
  logger.success('🧭 Created: lib/routes/routes_exports.dart');
}

// ------------------------------------------------------------------
// 🧩 Create Dependency Injection (GetIt)
// ------------------------------------------------------------------
void _createDependencyInjection(Directory libDir, Logger logger) {
  File('${libDir.path}/core/di/injection_container.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../networks/networks_exports.dart';
import '../theme/theme_exports.dart';
import '../../features/auth/auth_exports.dart';
// GENERATED_IMPORTS_START

// GENERATED_IMPORTS_END

final sl = GetIt.instance;

Future<void> setupLocator() async {
  await coreDependencies();

  await authDependencies();
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

  // provider
  sl.registerFactory<SigninViewModel>(
    () => SigninViewModel(signinUsecase: sl()),
  );
}

// GENERATED_DEPENDENCIES_END
''');
  logger.success('🧱 Created: lib/core/di/injection_container.dart');
}
