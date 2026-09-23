import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../theme/theme_utils.dart';

class CustomSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Color? fillColor;
  final Color? borderColor;

  const CustomSearchField({
    super.key,
    this.hintText = "Search",
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Default colors based on theme
    final defaultFillColor = fillColor ?? context.surface;
    final defaultBorderColor =
        borderColor ?? context.grey300.withValues(alpha: 0.6);

    return TextField(
      autofocus: false,
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: context.bodySmall.copyWith(color: context.textPrimary),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        hintText: hintText,
        hintStyle: context.bodySmall.copyWith(color: context.textSecondary),
        prefixIcon: Icon(
          Iconsax.search_normal,
          color: context.grey500,
          size: 20,
        ),
        filled: true,
        fillColor: defaultFillColor,

        // Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: defaultBorderColor),
        ),

        // Enabled border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: defaultBorderColor),
        ),

        // Focused border - uses brand color
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryAccent, width: 2),
        ),
      ),
    );
  }
}
