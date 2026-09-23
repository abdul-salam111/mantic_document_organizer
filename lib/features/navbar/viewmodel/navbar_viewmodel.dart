import 'package:flutter/foundation.dart';

class NavbarViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// Handles the system back gesture/button. Not on the Home tab -> jump
  /// to Home instead of exiting. On Home tab -> allow the app to exit.
  /// Returns true if the app should be allowed to exit.
  bool handleBackPressed() {
    if (_selectedIndex != 0) {
      selectTab(0);
      return false;
    }
    return true;
  }
}
