import 'package:flutter/material.dart';

import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';

/// Grid/list view-mode switch — shared by every screen that offers both
/// layouts for the same content (Home's categories, favorites, ...).
class ViewModeToggle extends StatelessWidget {
  final bool isGridView;
  final ValueChanged<bool> onChanged;

  const ViewModeToggle({
    super.key,
    required this.isGridView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _ViewModeButton(
          icon: Iconsax.element_3,
          isSelected: isGridView,
          onTap: () => onChanged(true),
        ),
        widthBox(6),
        _ViewModeButton(
          icon: Iconsax.row_vertical,
          isSelected: !isGridView,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(8),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: .center,
        decoration: BoxDecoration(
          color: isSelected ? context.primary : context.surface,
          borderRadius: .circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? context.white : context.textSecondary,
        ),
      ),
    );
  }
}
