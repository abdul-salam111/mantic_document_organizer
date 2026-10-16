import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../routes/routes_exports.dart';

enum ToastType { success, error, warning, info, custom }

class AppToastsUtils {
  AppToastsUtils._();

  static BuildContext? get _context => AppNavigator.navigatorKey.currentContext;

  // Tracked so a toast shown while another is already up replaces it
  // instead of stacking (Flushbar renders each as its own overlay route),
  // and so [dismissCurrent] has something to dismiss.
  static Flushbar<void>? _current;

  /// Shown anchored to the top of the screen -- below the status bar/notch
  /// via Flushbar's own `safeArea` handling -- rather than the bottom, so it
  /// never competes with the bottom nav bar or a bottom sheet/keyboard.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    SnackBarAction? action,
    bool showProgressIndicator = false,
  }) {
    final config = _getToastConfig(type);
    final colors = Theme.of(context).colorScheme;

    final surface = backgroundColor ?? colors.inverseSurface;
    final onSurface = textColor ?? colors.onInverseSurface;

    _current?.dismiss();
    final bar = Flushbar<void>(
      title: title,
      message: message,
      icon: showProgressIndicator
          ? null
          : Icon(icon ?? config.icon, color: iconColor ?? onSurface, size: 20),
      showProgressIndicator: showProgressIndicator,
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(
        iconColor ?? onSurface,
      ),
      titleColor: onSurface,
      messageColor: onSurface,
      backgroundColor: surface,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      duration: duration,
      onTap: onTap == null ? null : (_) => onTap(),
      mainButton: action == null
          ? null
          : TextButton(
              onPressed: action.onPressed,
              child: Text(
                action.label,
                style: TextStyle(color: action.textColor ?? onSurface),
              ),
            ),
    );
    _current = bar;
    bar.show(context).then((_) {
      if (identical(_current, bar)) _current = null;
    });
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
    );
  }

  static void success(String message, {String? title}) {
    final ctx = _context;
    if (ctx != null) showSuccess(ctx, message, title: title);
  }

  static void error(String message, {String? title}) {
    final ctx = _context;
    if (ctx != null) showError(ctx, message, title: title);
  }

  static void warning(String message, {String? title}) {
    final ctx = _context;
    if (ctx != null) showWarning(ctx, message, title: title);
  }

  static void info(String message, {String? title}) {
    final ctx = _context;
    if (ctx != null) showInfo(ctx, message, title: title);
  }

  static void loading(String message) {
    final ctx = _context;
    if (ctx != null) showLoading(ctx, message);
  }

  static void withAction({
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    ToastType type = ToastType.info,
  }) {
    final ctx = _context;
    if (ctx != null) {
      showWithAction(
        ctx,
        message: message,
        actionText: actionText,
        onActionPressed: onActionPressed,
        type: type,
      );
    }
  }

  static void custom({
    required String message,
    String? title,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _context;
    if (ctx != null) {
      show(
        ctx,
        message: message,
        title: title,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
      );
    }
  }

  /// Loading toast — does not auto-dismiss; call [dismissCurrent] when done.
  static void showLoading(BuildContext context, String message) {
    show(
      context,
      message: message,
      title: 'Loading',
      type: ToastType.info,
      duration: const Duration(days: 1),
      showProgressIndicator: true,
    );
  }

  /// Toast with an action button -- [SnackBarAction] is just reused as the
  /// label/callback carrier here, not actually rendered by a [SnackBar].
  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    ToastType type = ToastType.info,
  }) {
    final colors = Theme.of(context).colorScheme;
    show(
      context,
      message: message,
      type: type,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: actionText,
        textColor: colors.onInverseSurface,
        onPressed: onActionPressed,
      ),
    );
  }

  static void showPersistent(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    show(
      context,
      message: message,
      type: type,
      duration: const Duration(days: 1),
    );
  }

  static void showLong(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    show(
      context,
      message: message,
      type: type,
      duration: const Duration(seconds: 5),
    );
  }

  static void showShort(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    show(
      context,
      message: message,
      type: type,
      duration: const Duration(seconds: 1),
    );
  }

  static void dismissCurrent() {
    _current?.dismiss();
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(icon: Icons.check_circle_rounded);
      case ToastType.error:
        return _ToastConfig(icon: Icons.error_outline_rounded);
      case ToastType.warning:
        return _ToastConfig(icon: Icons.warning_amber_rounded);
      case ToastType.info:
        return _ToastConfig(icon: Icons.info_outline_rounded);
      case ToastType.custom:
        return _ToastConfig(icon: Icons.notifications_rounded);
    }
  }
}

class _ToastConfig {
  final IconData icon;
  _ToastConfig({required this.icon});
}
