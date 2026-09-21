import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

import '../../routes/routes_exports.dart';

// ============================================================================
// TOAST POSITION ENUM 📍
// ============================================================================

enum ToastPosition {
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

// ============================================================================
// TOAST TYPE ENUM 🎨
// ============================================================================

enum ToastType { success, error, warning, info, custom }

// ============================================================================
// COMPLETE TOAST UTILITY 🎯
// ============================================================================

class AppToastsUtils {
  static Flushbar<dynamic>? _currentFlushbar;

  // ========================================================================
  // DISMISS CURRENT TOAST
  // ========================================================================

  static void _dismissCurrentToast() {
    if (_currentFlushbar != null && _currentFlushbar!.isShowing()) {
      _currentFlushbar!.dismiss();
      _currentFlushbar = null;
    }
  }

  // ========================================================================
  // MAIN SHOW METHOD (WITH ALL OPTIONS) 🎨
  // ========================================================================

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? mainButton,
    bool isDismissible = true,
    bool showProgressIndicator = false,
    double? maxWidth,
  }) {
    _dismissCurrentToast();

    // Get config based on type
    final config = _getToastConfig(type);

    // Get position settings
    final positionConfig = _getPositionConfig(position);

    _currentFlushbar = Flushbar(
      title: title ?? config.title,
      message: message,
      backgroundColor: backgroundColor ?? config.backgroundColor,
      messageColor: textColor ?? Colors.white,
      titleColor: textColor ?? Colors.white,
      icon: icon != null
          ? Icon(icon, color: iconColor ?? Colors.white)
          : Icon(config.icon, color: iconColor ?? Colors.white),
      duration: duration,
      flushbarPosition: positionConfig.flushbarPosition,
      margin: positionConfig.margin,
      borderRadius: BorderRadius.circular(12),
      isDismissible: isDismissible,
      dismissDirection: positionConfig.dismissDirection,
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      boxShadows: const [
        BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 8),
      ],
      mainButton: mainButton,
      onTap: onTap != null ? (_) => onTap() : null,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorBackgroundColor: Colors.white24,
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(
        textColor ?? Colors.white,
      ),
      maxWidth: maxWidth,
    )..show(context).then((_) => _currentFlushbar = null);
  }

  // ========================================================================
  // PREDEFINED TOAST METHODS 🎯
  // ========================================================================

  // ✅ SUCCESS TOAST
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      position: position,
      duration: duration,
    );
  }

  // ❌ ERROR TOAST
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      position: position,
      duration: duration,
    );
  }

  // ⚠️ WARNING TOAST
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      position: position,
      duration: duration,
    );
  }

  // ℹ️ INFO TOAST
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      position: position,
      duration: duration,
    );
  }

  // ========================================================================
  // DIRECTION-SPECIFIC METHODS 📍
  // ========================================================================
  static BuildContext? get _context => AppNavigator.navigatorKey.currentContext;

  // SUCCESS
  static void success(
    String message, {
    String? title,
    ToastPosition? position,
  }) {
    if (_context != null) {
      showSuccess(
        _context!,
        message,
        title: title,
        position: position ?? ToastPosition.top,
      );
    }
  }

  // ERROR
  static void error(String message, {String? title, ToastPosition? position}) {
    if (_context != null) {
      showError(
        _context!,
        message,
        title: title,
        position: position ?? ToastPosition.top,
      );
    }
  }

  // WARNING
  static void warning(
    String message, {
    String? title,
    ToastPosition? position,
  }) {
    if (_context != null) {
      showWarning(
        _context!,
        message,
        title: title,
        position: position ?? ToastPosition.top,
      );
    }
  }

  // INFO
  static void info(String message, {String? title, ToastPosition? position}) {
    if (_context != null) {
      showInfo(
        _context!,
        message,
        title: title,
        position: position ?? ToastPosition.top,
      );
    }
  }

  // LOADING
  static void loading(String message, {ToastPosition? position}) {
    if (_context != null) {
      showLoading(_context!, message, position: position ?? ToastPosition.top);
    }
  }

  // WITH ACTION
  static void withAction({
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    ToastType? type,
  }) {
    if (_context != null) {
      showWithAction(
        _context!,
        message: message,
        actionText: actionText,
        onActionPressed: onActionPressed,
        type: type ?? ToastType.info,
      );
    }
  }

  // CUSTOM
  static void custom({
    required String message,
    String? title,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    ToastPosition? position,
    Duration? duration,
  }) {
    if (_context != null) {
      show(
        _context!,
        message: message,
        title: title,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        position: position ?? ToastPosition.top,
        duration: duration ?? const Duration(seconds: 3),
      );
    }
  }

  // TOP TOASTS
  static void showSuccessTop(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.top);
  }

  static void showErrorTop(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.top);
  }

  static void showWarningTop(BuildContext context, String message) {
    showWarning(context, message, position: ToastPosition.top);
  }

  static void showInfoTop(BuildContext context, String message) {
    showInfo(context, message, position: ToastPosition.top);
  }

  // BOTTOM TOASTS
  static void showSuccessBottom(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.bottom);
  }

  static void showErrorBottom(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.bottom);
  }

  static void showWarningBottom(BuildContext context, String message) {
    showWarning(context, message, position: ToastPosition.bottom);
  }

  static void showInfoBottom(BuildContext context, String message) {
    showInfo(context, message, position: ToastPosition.bottom);
  }

  // TOP LEFT TOASTS
  static void showSuccessTopLeft(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.topLeft);
  }

  static void showErrorTopLeft(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.topLeft);
  }

  // TOP RIGHT TOASTS
  static void showSuccessTopRight(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.topRight);
  }

  static void showErrorTopRight(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.topRight);
  }

  // BOTTOM LEFT TOASTS
  static void showSuccessBottomLeft(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.bottomLeft);
  }

  static void showErrorBottomLeft(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.bottomLeft);
  }

  // BOTTOM RIGHT TOASTS
  static void showSuccessBottomRight(BuildContext context, String message) {
    showSuccess(context, message, position: ToastPosition.bottomRight);
  }

  static void showErrorBottomRight(BuildContext context, String message) {
    showError(context, message, position: ToastPosition.bottomRight);
  }

  // CENTER TOAST
  static void showCenter(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    show(context, message: message, type: type, position: ToastPosition.center);
  }

  // ========================================================================
  // SPECIAL TOASTS 🌟
  // ========================================================================

  // Loading Toast
  static void showLoading(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context,
      message: message,
      title: 'Loading',
      type: ToastType.info,
      position: position,
      duration: const Duration(days: 1), // Won't auto-dismiss
      showProgressIndicator: true,
      isDismissible: false,
    );
  }

  // Toast with Action Button
  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
  }) {
    show(
      context,
      message: message,
      type: type,
      position: position,
      mainButton: TextButton(
        onPressed: () {
          dismissCurrent();
          onActionPressed();
        },
        child: Text(actionText, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // Persistent Toast (doesn't auto-dismiss)
  static void showPersistent(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context,
      message: message,
      type: type,
      position: position,
      duration: const Duration(days: 1), // Won't auto-dismiss
      isDismissible: true,
    );
  }

  // Long Duration Toast
  static void showLong(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context,
      message: message,
      type: type,
      position: position,
      duration: const Duration(seconds: 5),
    );
  }

  // Short Duration Toast
  static void showShort(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context,
      message: message,
      type: type,
      position: position,
      duration: const Duration(seconds: 1),
    );
  }

  // ========================================================================
  // HELPER METHODS 🔧
  // ========================================================================

  static void dismissCurrent() {
    _dismissCurrentToast();
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          title: 'Success',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      case ToastType.error:
        return _ToastConfig(
          title: 'Error',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      case ToastType.warning:
        return _ToastConfig(
          title: 'Warning',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
        );
      case ToastType.info:
        return _ToastConfig(
          title: 'Info',
          backgroundColor: Colors.blue,
          icon: Icons.info,
        );
      case ToastType.custom:
        return _ToastConfig(
          title: '',
          backgroundColor: Colors.grey,
          icon: Icons.notifications,
        );
    }
  }

  static _PositionConfig _getPositionConfig(ToastPosition position) {
    switch (position) {
      case ToastPosition.top:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(8),
          dismissDirection: FlushbarDismissDirection.VERTICAL,
        );
      case ToastPosition.bottom:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: const EdgeInsets.all(8),
          dismissDirection: FlushbarDismissDirection.VERTICAL,
        );
      case ToastPosition.topLeft:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.only(left: 8, top: 8, right: 200),
          dismissDirection: FlushbarDismissDirection.HORIZONTAL,
        );
      case ToastPosition.topRight:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.only(left: 200, top: 8, right: 8),
          dismissDirection: FlushbarDismissDirection.HORIZONTAL,
        );
      case ToastPosition.bottomLeft:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: const EdgeInsets.only(left: 8, bottom: 8, right: 200),
          dismissDirection: FlushbarDismissDirection.HORIZONTAL,
        );
      case ToastPosition.bottomRight:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: const EdgeInsets.only(left: 200, bottom: 8, right: 8),
          dismissDirection: FlushbarDismissDirection.HORIZONTAL,
        );
      case ToastPosition.center:
        return _PositionConfig(
          flushbarPosition: FlushbarPosition.TOP,
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical:
                MediaQueryData.fromView(
                  WidgetsBinding.instance.platformDispatcher.views.first,
                ).size.height *
                0.4,
          ),
          dismissDirection: FlushbarDismissDirection.VERTICAL,
        );
    }
  }
}

// ============================================================================
// HELPER CLASSES 🎨
// ============================================================================

class _ToastConfig {
  final String title;
  final Color backgroundColor;
  final IconData icon;

  _ToastConfig({
    required this.title,
    required this.backgroundColor,
    required this.icon,
  });
}

class _PositionConfig {
  final FlushbarPosition flushbarPosition;
  final EdgeInsets margin;
  final FlushbarDismissDirection dismissDirection;

  _PositionConfig({
    required this.flushbarPosition,
    required this.margin,
    required this.dismissDirection,
  });
}
