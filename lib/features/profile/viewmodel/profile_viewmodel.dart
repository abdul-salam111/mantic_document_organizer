import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';
import '../../auth/domain/entities/auth_entity.dart';

class ProfileViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;

  ProfileViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
    _loadSession();
    _loadAppVersion();
  }

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? get userName => SessionController.instance.userDetails.name;
  String? get userEmail => SessionController.instance.userDetails.email;

  int get documentCount => _documentUseCases.documents.length;
  int get categoryCount => _categoryUseCases.categories.length;
  int get favoriteCount =>
      _documentUseCases.documents.where((d) => d.isFavorite).length;

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
    await storage.clearValues(StorageKeys.loggedIn);
    await storage.clearValues(StorageKeys.token);
    await storage.clearValues(StorageKeys.refreshToken);
    await storage.clearValues(StorageKeys.userId);
    await storage.clearValues(StorageKeys.userDetails);
    SessionController.instance.islogin = false;
    SessionController.instance.userToken = null;
    SessionController.instance.userId = null;
    SessionController.instance.userDetails = const AuthEntity(id: '');
    _isSignedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
