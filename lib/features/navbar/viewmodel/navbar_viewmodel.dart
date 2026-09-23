import 'package:flutter/foundation.dart';

import '../../../core/localization/localization_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../routes/routes_exports.dart';

class NavbarViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  DateTime? _lastBackPressAt;
  static const _exitPressWindow = Duration(seconds: 2);

  /// Handles the system back gesture/button. Not on the Home tab -> jump
  /// to Home. On Home tab -> require a second press within
  /// [_exitPressWindow] before actually exiting, to avoid accidental exits.
  /// Returns true if the app should be allowed to exit.
  bool handleBackPressed() {
    if (_selectedIndex != 0) {
      selectTab(0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressAt != null &&
        now.difference(_lastBackPressAt!) < _exitPressWindow) {
      return true;
    }

    _lastBackPressAt = now;
    final context = AppNavigator.navigatorKey.currentContext;
    if (context != null) {
      AppToastsUtils.info(AppLocalizations.of(context).pressBackAgainToExit);
    }
    return false;
  }
}
