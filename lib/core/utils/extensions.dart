import 'package:flutter/material.dart';

///////////////////////////////// BUILD CONTEXT /////////////////////////////////////////////////
extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  // Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  // Get the padding (safe area) from the top (e.g., status bar)
  double get paddingTop => MediaQuery.of(this).padding.top;

  // Get the padding (safe area) from the bottom (e.g., navigation bar)
  double get paddingBottom => MediaQuery.of(this).padding.bottom;

  // Get the device pixel ratio
  double get pixelRatio => MediaQuery.of(this).devicePixelRatio;

  // Get the platform brightness (light/dark mode)
  Brightness get platformBrightness => MediaQuery.of(this).platformBrightness;

  // Check if the device is in landscape orientation
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  // Check if the device is in portrait orientation
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  // Get the current locale
  Locale get locale => Localizations.localeOf(this);

  // Get the current navigator state
  NavigatorState get navigator => Navigator.of(this);

  BouncingScrollPhysics get bouncingScrollPhysics =>
      const BouncingScrollPhysics();

  NeverScrollableScrollPhysics get neverScrollableScrollPhysics =>
      const NeverScrollableScrollPhysics();

  // Get the current scaffold state
  ScaffoldState get scaffold => Scaffold.of(this);

  // Get the current overlay state
  OverlayState? get overlay => Overlay.of(this);

  // Get the current focus scope
  FocusScopeNode get focusScope => FocusScope.of(this);

  // Get the current form state
  FormState? get formState => Form.of(this);

  // Get the current scroll controller
  ScrollController? get scrollController => PrimaryScrollController.of(this);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

// Note: validation getters (isValidPassword, isNumeric, isPalindrome, etc.)
// live in validators.dart's StringValidationExtensions — the single source
// of truth for validation. Numeric parsing (toDoubleOrNull/toIntOrNull)
// lives in currency_utils.dart's StringToNumber. Do not redeclare them here:
// duplicate extension members on the same type cause ambiguous-extension
// compile errors wherever both are in scope (see TEMPLATE_REVIEW.md §1.1).
extension StringExtensions on String {
  // Check if the string is empty or blank
  bool get isNullOrEmpty => trim().isEmpty;

  // Capitalize the first letter of the string
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  // Truncate the string to a specific length and add an ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  // Remove all whitespace from the string
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  // Reverse the string
  String get reverse => split('').reversed.join();

  // Wrap the string in a Text widget
  Text toText({TextStyle? style}) {
    return Text(this, style: style);
  }
}

// Create a SizedBox with a specific height
SizedBox heightBox(double height) {
  return SizedBox(height: height);
}

// Create a SizedBox with a specific width
SizedBox widthBox(double width) {
  return SizedBox(width: width);
}
