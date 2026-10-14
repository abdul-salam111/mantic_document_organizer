import 'package:flutter/material.dart';

import '../../theme/theme_exports.dart';
import '../../utils/utils_exports.dart';
import '../buttons/custom_button.dart';

/// A destructive/confirmation dialog with its own pop-in/pop-out
/// animation — [showGeneralDialog] directly rather than [showDialog],
/// since [showDialog]'s `AlertDialog` is stuck with Material's default
/// fade+scale and offers no way to customize it. Used for actions worth
/// pausing on (sign out, delete account, ...) instead of the plain
/// `AlertDialog` used for routine confirmations elsewhere.
///
/// Returns `true` only when [confirmLabel] was tapped — dismissed any
/// other way (barrier tap, back gesture, [cancelLabel]) resolves to
/// `false`, same contract `showDialog<bool>` callers already expect.
Future<bool> showAnimatedConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
}) async {
  final resolvedCancelLabel =
      cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AnimatedConfirmDialog(
          icon: icon,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: resolvedCancelLabel,
          isDestructive: isDestructive,
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // easeOutBack on the way in for a soft overshoot "pop"; a plain
      // easeIn on the way out (via reverseCurve) so closing just shrinks
      // away cleanly instead of re-playing that overshoot in reverse.
      final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
  return result ?? false;
}

class _AnimatedConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const _AnimatedConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? context.errorAccent : context.primary;
    return Center(
      child: Padding(
        padding: const .symmetric(horizontal: 32),
        child: Material(
          color: context.surfaceElevated,
          borderRadius: .circular(24),
          elevation: 16,
          shadowColor: context.black.withValues(alpha: 0.3),
          child: Padding(
            padding: const .fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: .min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: .center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: .circle,
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
                heightBox(18),
                Text(
                  title,
                  textAlign: .center,
                  style: context.titleMedium.copyWith(fontWeight: .w700),
                ),
                heightBox(8),
                Text(
                  message,
                  textAlign: .center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                heightBox(24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: cancelLabel,
                        onPressed: () => Navigator.of(context).pop(false),
                        backgroundColor: context.transparent,
                        textColor: context.textPrimary,
                        borderColor: context.border,
                        radius: 14,
                      ),
                    ),
                    widthBox(12),
                    Expanded(
                      child: CustomButton(
                        text: confirmLabel,
                        onPressed: () => Navigator.of(context).pop(true),
                        backgroundColor: accent,
                        radius: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
