import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/theme_exports.dart';
import '../../utils/utils_exports.dart';

class CustomTextFormField extends StatefulWidget {
  final String? hintText;
  final String? label;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final int maxLines;
  final Color? fillColor;
  final Color? borderColor;
  final Color? labelColor;
  final bool isRequired;
  final double labelFontSize;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    this.hintText,
    this.label,
    this.readOnly = false,
    this.prefixIcon,
    this.isRequired = false,
    this.fillColor,
    this.borderColor,
    this.controller,
    this.labelColor,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.labelFontSize = 16.0,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.textInputAction,
    this.inputFormatters,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool isObscure;

  @override
  void initState() {
    super.initState();
    isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final defaultLabelColor = widget.labelColor ?? context.textSecondary;

    // Only build an explicit border when the caller overrides borderColor —
    // otherwise leave it unset so Theme.of(context).inputDecorationTheme
    // (core/theme/theme.dart) drives shape/radius/color, keeping theming
    // in one place instead of duplicated here.
    OutlineInputBorder? borderWith(Color color, {double width = 1}) {
      if (widget.borderColor == null) return null;
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with optional required asterisk
        if (widget.label != null)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.label!,
                  style: context.bodySmall.copyWith(
                    color: defaultLabelColor,
                    fontSize: widget.labelFontSize,
                  ),
                ),
                if (widget.isRequired)
                  TextSpan(
                    text: " *",
                    style: context.bodyMedium.copyWith(
                      color: context.error,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.labelFontSize,
                    ),
                  ),
              ],
            ),
          ),

        if (widget.label != null) heightBox(5),

        // Text Form Field
        TextFormField(
          autofocus: false,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readOnly,
          style: context.bodySmall.copyWith(color: context.textPrimary),
          controller: widget.controller,
          obscureText: isObscure,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: context.bodySmall.copyWith(color: context.textSecondary),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: context.grey500, size: 20)
                : null,
            filled: widget.fillColor != null ? true : null,
            fillColor: widget.fillColor,
            contentPadding: const EdgeInsets.only(left: 10),

            border: borderWith(widget.borderColor ?? context.border),
            enabledBorder: borderWith(widget.borderColor ?? context.border),
            focusedBorder: borderWith(context.primaryAccent, width: 2),
            errorBorder: borderWith(context.errorAccent),
            focusedErrorBorder: borderWith(context.errorAccent, width: 2),

            // Suffix icon for password visibility toggle
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      isObscure ? Iconsax.eye_slash : Iconsax.eye,
                      color: context.grey500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isObscure = !isObscure;
                      });
                    },
                  )
                : null,
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
        ),
      ],
    );
  }
}
