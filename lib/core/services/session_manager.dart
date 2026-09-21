import 'dart:convert';

import '../local_storage/local_storage_exports.dart';
import '../../features/auth/auth_exports.dart';

class SessionController {
  static final SessionController _instance = SessionController._internal();

  SessionController._internal();

  /// The one sanctioned way to reach this singleton — there is no bare
  /// `SessionController()` constructor, so there's only one access pattern
  /// to remember.
  static SessionController get instance => _instance;

  AuthEntity userDetails = const AuthEntity(id: '');
  bool islogin = false;
  String? userId;
  String? userToken;

  Future<void> saveUserInStorage(AuthEntity user) async {
    await storage.setValues(
      StorageKeys.userDetails,
      jsonEncode(user.toJson()),
    );
    await storage.setValues(StorageKeys.loggedIn, 'true');
    await storage.setValues(StorageKeys.token, user.token ?? "");
  }

  /// Loads the persisted user/login state from secure storage (see
  /// core/local_storage/storage.dart — not SharedPreferences, despite the
  /// old name of this method).
  Future<void> loadUserFromStorage() async {
    try {
      final userData = await storage.readValues(StorageKeys.userDetails);
      if (userData != null) {
        userDetails = AuthEntity.fromJson(jsonDecode(userData));
      }
      final isLoggedIn = await storage.readValues(StorageKeys.loggedIn);
      islogin = isLoggedIn == 'true';
    } catch (e) {
      throw Exception(e);
    }
  }
}
