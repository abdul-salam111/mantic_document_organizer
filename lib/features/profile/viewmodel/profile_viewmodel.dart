import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? get userName => SessionController.instance.userDetails.name;
  String? get userEmail => SessionController.instance.userDetails.email;

  ProfileViewModel() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    await SessionController.instance.loadUserFromStorage();
    _isSignedIn = SessionController.instance.islogin;
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
}
