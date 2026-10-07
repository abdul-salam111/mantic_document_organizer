import 'package:flutter/material.dart';

/// Shows a non-dismissible loading popup on the *root* navigator and returns
/// a handle that [dismissLoadingPopup] uses to close this exact route —
/// popping by identity avoids the "which navigator does this context
/// resolve to?" trap that `showDialog`'s root-navigator default creates.
Future<void> Function() showLoadingPopup(
  BuildContext context, {
  String message = 'Please wait...',
}) {
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _LoadingPopup(message: message),
  );

  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.push(route);

  return () async {
    if (route.isActive) navigator.removeRoute(route);
  };
}

Future<void> dismissLoadingPopup(Future<void> Function()? dismiss) async {
  if (dismiss == null) return;
  await dismiss();
}

class _LoadingPopup extends StatelessWidget {
  final String message;

  const _LoadingPopup({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Center(
        // Material *is* the card here: color = surface, elevation gives it
        // the soft shadow, borderRadius rounds it. This also supplies the
        // Material ancestor Text needs — without it, the Text renders with
        // Flutter's "missing Material" yellow debug stripes.
        child: Material(
          color: colors.surface,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: colors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}