import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';
import '../../../core/shared/shared_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../auth/auth_exports.dart';

class ProfileViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;
  final SignoutUsecase _signoutUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;

  ProfileViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
    required SignoutUsecase signoutUsecase,
    required DeleteAccountUsecase deleteAccountUsecase,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases,
       _signoutUsecase = signoutUsecase,
       _deleteAccountUsecase = deleteAccountUsecase {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
    _loadSession();
    _loadAppVersion();
  }

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;
  bool _isSigningOut = false;
  bool get isSigningOut => _isSigningOut;
  bool _isDeletingAccount = false;
  bool get isDeletingAccount => _isDeletingAccount;

  String? get userName => SessionController.instance.userDetails.name;
  String? get userEmail => SessionController.instance.userDetails.email;

  int get documentCount => _documentUseCases.documents.length;
  int get categoryCount => _categoryUseCases.categories.length;
  int get favoriteCount =>
      _documentUseCases.documents.where((d) => d.isFavorite).length;
  int get expiringSoonCount => _documentUseCases.expiringSoon().length;

  String? _appVersion;
  String? get appVersion => _appVersion;

  Future<void> _loadSession() async {
    await SessionController.instance.loadUserFromStorage();
    _isSignedIn = SessionController.instance.islogin;
    notifyListeners();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    _appVersion = 'v${info.version} (${info.buildNumber})';
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_isSigningOut) return;
    _isSigningOut = true;
    notifyListeners();

    final refreshToken = await storage.readValues(StorageKeys.refreshToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final result = await _signoutUsecase(refreshToken);
      if (result case Failure<void>(:final error)) {
        _isSigningOut = false;
        notifyListeners();
        AppToastsUtils.error(error.message);
        return;
      }
    }

    await SessionController.instance.clearSession();
    _isSignedIn = false;
    _isSigningOut = false;
    notifyListeners();
    // Signup/login is mandatory — signing out leaves the app, it doesn't
    // drop into a local-only in-app state.
    AppNavigator.goNamed(RouteNames.signin);
  }

  Future<void> deleteAccount() async {
    if (_isDeletingAccount) return;
    final accessToken = SessionController.instance.userToken;
    if (accessToken == null || accessToken.isEmpty) return;

    _isDeletingAccount = true;
    notifyListeners();

    final result = await _deleteAccountUsecase(accessToken);
    if (result case Failure<void>(:final error)) {
      _isDeletingAccount = false;
      notifyListeners();
      AppToastsUtils.error(error.message);
      return;
    }

    await SessionController.instance.clearSession();
    _isSignedIn = false;
    _isDeletingAccount = false;
    notifyListeners();
    AppNavigator.goNamed(RouteNames.signin);
  }

  Future<void> setUpBackup() async {
    if (_isSignedIn) {
      AppNavigator.pushNamed(RouteNames.backupSetup);
      return;
    }
    await storage.setValues(StorageKeys.pendingBackupSetup, 'true');
    AppNavigator.goNamed(RouteNames.signin);
  }

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
