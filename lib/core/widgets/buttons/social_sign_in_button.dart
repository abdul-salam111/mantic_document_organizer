import 'package:flutter/material.dart';

/// An OutlinedButton for a "Continue with Google/Apple" action, sized to
/// sit side-by-side with its counterpart in a [Row] rather than stacked
/// full-width. [label] is wrapped in a [FittedBox] so the full "Continue
/// with ___" text auto-shrinks to fit the half-width space instead of
/// truncating or wrapping.
class SocialSignInButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  /// True for a monochrome asset (e.g. the Apple glyph) that needs tinting
  /// to the current icon color; false for an already-colored logo (e.g.
  /// Google's) that should render as-is.
  final bool tintIcon;

  const SocialSignInButton({
    super.key,
    required this.icon,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.tintIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.asset(
                icon,
                width: 20,
                height: 20,
                color: tintIcon ? IconTheme.of(context).color : null,
                colorBlendMode: tintIcon ? BlendMode.srcIn : null,
              ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }
}
