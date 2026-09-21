import 'dart:async';
import 'package:flutter/foundation.dart';

import 'session_manager.dart';
import '../../routes/routes_exports.dart';

class SplashServices {
  void isLoggedIn() {
    Future.delayed(Duration(seconds: 2), () {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    try {
      await SessionController.instance.loadUserFromStorage();

      if (SessionController.instance.islogin == true) {
        AppNavigator.goNamed(RouteNames.signin);
      } else {
        AppNavigator.goNamed(RouteNames.signin);
      }
    } catch (e) {
      debugPrint('Error in checkLoginStatus: $e');
    }
  }
}
