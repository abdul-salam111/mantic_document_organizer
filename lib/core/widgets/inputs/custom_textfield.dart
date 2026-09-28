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
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final int? minLines;
  final int maxLines;
  final Color? fillColor;
  final Color? borderColor;
  final Color? labelColor;
  final bool isRequired;
  final double labelFontSize;
  final bool readOnly;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool showBorder;
  final bool isCollapsed;
  final EdgeInsetsGeometry? contentPadding;

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
    this.focusNode,
    this.labelColor,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.labelFontSize = 16.0,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.showBorder = true,
    this.isCollapsed = false,
    this.contentPadding,
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
      mainAxisSize: MainAxisSize.min,
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
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readOnly,
          style:
              widget.style ??
              context.bodySmall.copyWith(color: context.textPrimary),
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: isObscure,
          keyboardType: widget.keyboardType,
          minLines: widget.obscureText ? null : widget.minLines,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            isCollapsed: widget.isCollapsed,
            hintText: widget.hintText,
            hintStyle:
                widget.style?.copyWith(color: context.textSecondary) ??
                context.bodySmall.copyWith(color: context.textSecondary),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: context.grey500, size: 20)
                : null,
            filled: widget.fillColor != null ? true : null,
            fillColor: widget.fillColor,
            contentPadding:
                widget.contentPadding ?? const EdgeInsets.only(left: 10),

            border: widget.showBorder
                ? borderWith(widget.borderColor ?? context.border)
                : InputBorder.none,
            enabledBorder: widget.showBorder
                ? borderWith(widget.borderColor ?? context.border)
                : InputBorder.none,
            focusedBorder: widget.showBorder
                ? borderWith(context.primaryAccent, width: 2)
                : InputBorder.none,
            errorBorder: widget.showBorder
                ? borderWith(context.errorAccent)
                : InputBorder.none,
            focusedErrorBorder: widget.showBorder
                ? borderWith(context.errorAccent, width: 2)
                : InputBorder.none,

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
