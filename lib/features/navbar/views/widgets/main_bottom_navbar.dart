import 'package:flutter/material.dart';

import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';

class MainBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  const MainBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  static const double _barHeight = 68;
  static const double _buttonSize = 60;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _barHeight + _buttonSize / 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: .bottomCenter,
          children: [
            Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: context.surfaceElevated,
                borderRadius: const .only(
                  topLeft: .circular(24),
                  topRight: .circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.shadow.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Iconsax.home,
                      activeIcon: Iconsax.home5,
                      label: 'Home',
                      isActive: selectedIndex == 0,
                      onTap: () => onTabSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Iconsax.search_normal,
                      activeIcon: Iconsax.search_normal,
                      label: 'Search',
                      isActive: selectedIndex == 1,
                      onTap: () => onTabSelected(1),
                    ),
                  ),
                  const SizedBox(width: _buttonSize),
                  Expanded(
                    child: _NavItem(
                      icon: Iconsax.heart,
                      activeIcon: Iconsax.heart5,
                      label: 'Favorites',
                      isActive: selectedIndex == 2,
                      onTap: () => onTabSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Iconsax.setting_2,
                      activeIcon: Iconsax.setting_25,
                      label: 'Settings',
                      isActive: selectedIndex == 3,
                      onTap: () => onTabSelected(3),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: _AddButton(size: _buttonSize, onPressed: onAddPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.primaryAccent : context.textSecondary;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: .symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            heightBox(4),
            Text(
              label,
              style: context.labelSmall.copyWith(
                color: color,
                fontWeight: isActive ? .bold : .normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final double size;
  final VoidCallback onPressed;

  const _AddButton({required this.size, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      alignment: .center,
      decoration: BoxDecoration(shape: .circle, color: context.surfaceElevated),
      child: Material(
        shape: const CircleBorder(),
        color: context.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: .center,
            decoration: BoxDecoration(
              shape: .circle,
              gradient: LinearGradient(
                begin: .topLeft,
                end: .bottomRight,
                colors: [context.primaryLight, context.primary, context.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primary.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Iconsax.add, color: context.white, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
