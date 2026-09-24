import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';
import '../../home/home_exports.dart';

class ProfileViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;
  final DocumentLocalStore _documentStore;

  ProfileViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore {
    _categoryStore.addListener(notifyListeners);
    _documentStore.addListener(notifyListeners);
    _loadSession();
    _loadAppVersion();
  }

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? get userName => SessionController.instance.userDetails.name;
  String? get userEmail => SessionController.instance.userDetails.email;

  int get documentCount => _documentStore.documents.length;
  int get categoryCount => _categoryStore.categories.length;
  int get favoriteCount =>
      _documentStore.documents.where((d) => d.isFavorite).length;

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
    await storage.clearValues(StorageKeys.userDetails);
    SessionController.instance.islogin = false;
    _isSignedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
