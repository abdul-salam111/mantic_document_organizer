import 'package:flutter/material.dart';

import '../feedback/loading_indicator.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? radius;
  final double? padding;
  final double? elevation;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final bool isLoading;
  final double? fontSize;
  final Size size;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.radius,
    this.padding,
    this.fontSize,
    this.elevation,
    this.icon,
    this.iconSize = 24.0,
    this.iconColor,
    this.isLoading = false,
    this.size = const Size(double.infinity, 50),
  });

  @override
  Widget build(BuildContext context) {
    // Only override what's explicitly passed in — everything else falls
    // through to Theme.of(context).elevatedButtonTheme (core/theme/theme.dart)
    // so rebranding a cloned project only ever needs to touch the theme file.
    final theme = Theme.of(context);
    final baseStyle = theme.elevatedButtonTheme.style ?? const ButtonStyle();
    final resolvedTextColor = textColor ?? theme.colorScheme.onPrimary;
    final resolvedIconColor = iconColor ?? resolvedTextColor;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: baseStyle.copyWith(
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: backgroundColor != null
            ? WidgetStatePropertyAll(backgroundColor)
            : null,
        shape: radius != null
            ? WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius!),
                ),
              )
            : null,
        padding: padding != null
            ? WidgetStatePropertyAll(EdgeInsets.all(padding!))
            : null,
        elevation: elevation != null ? WidgetStatePropertyAll(elevation) : null,
        minimumSize: WidgetStatePropertyAll(size),
      ),
      child: isLoading
          ? const LoadingIndicator(size: 30)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, size: iconSize, color: resolvedIconColor),
                if (icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: (theme.textTheme.labelLarge ?? const TextStyle())
                        .copyWith(
                          color: resolvedTextColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
