import 'package:flutter/foundation.dart';

class NavbarViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  bool _focusSearchPending = false;

  /// [focusSearch] lets a caller (e.g. Home's search field) ask the All
  /// Docs tab to autofocus its own search field once it's shown, without
  /// the two tabs needing a direct reference to each other.
  void selectTab(int index, {bool focusSearch = false}) {
    final indexChanged = _selectedIndex != index;
    _selectedIndex = index;
    if (focusSearch) _focusSearchPending = true;
    if (indexChanged || focusSearch) notifyListeners();
  }

  /// Consumed by [SearchView] when it acts on a pending focus request, so
  /// later rebuilds/listener calls don't keep refocusing the field.
  bool consumeFocusSearchPending() {
    if (!_focusSearchPending) return false;
    _focusSearchPending = false;
    return true;
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
