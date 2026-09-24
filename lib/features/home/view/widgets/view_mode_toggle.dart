import 'package:flutter/material.dart';

import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';

/// Grid/list view-mode switch — shared by every screen that offers both
/// layouts for the same content (Home's categories, favorites, ...).
/// [onAppBar] swaps the color scheme for sitting directly on a
/// primary-colored `CustomAppBar` instead of a light page body — the
/// default (light-surface) colors would be nearly invisible there.
class ViewModeToggle extends StatelessWidget {
  final bool isGridView;
  final ValueChanged<bool> onChanged;
  final bool onAppBar;

  const ViewModeToggle({
    super.key,
    required this.isGridView,
    required this.onChanged,
    this.onAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _ViewModeButton(
          icon: Iconsax.element_3,
          isSelected: isGridView,
          onAppBar: onAppBar,
          onTap: () => onChanged(true),
        ),
        widthBox(6),
        _ViewModeButton(
          icon: Iconsax.row_vertical,
          isSelected: !isGridView,
          onAppBar: onAppBar,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool onAppBar;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onAppBar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBackground = onAppBar ? context.white : context.primary;
    final inactiveBackground = onAppBar
        ? context.white.withValues(alpha: 0.15)
        : context.surface;
    final activeIconColor = onAppBar ? context.primary : context.white;
    final inactiveIconColor = onAppBar ? context.white : context.textSecondary;

    return InkWell(
      borderRadius: .circular(8),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: .center,
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : inactiveBackground,
          borderRadius: .circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? activeIconColor : inactiveIconColor,
        ),
      ),
    );
  }
}
