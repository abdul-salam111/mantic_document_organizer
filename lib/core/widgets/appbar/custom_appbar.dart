import 'package:flutter/material.dart';

import '../../theme/theme_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// For screens reached as a bottom-nav tab (not a pushed route) —
  /// there's nothing on the Navigator stack to pop, so Flutter's default
  /// automatic back button never appears. Pass this to show one anyway
  /// (e.g. navigating back to the Home tab instead of popping a route).
  final VoidCallback? onBackPressed;

  final List<Widget>? actions;

  /// Overrides the default solid [AppColors.primary] bar — e.g. a flat,
  /// page-colored bar on a screen whose own content already carries the
  /// brand color, so it doesn't end up stacked under another blue block.
  final Color? backgroundColor;

  /// Icon/title color. Defaults to white, which only reads correctly on
  /// the default primary-colored bar — always pass this alongside a
  /// light [backgroundColor].
  final Color? foregroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? context.white;
    return AppBar(
      iconTheme: IconThemeData(color: fg),
      
      leading: onBackPressed != null
          ? _GlassBackButton(onPressed: onBackPressed!, iconColor: fg)
          : null,
      title: Text(
        title,
        style: context.bodyLarge.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? context.primary,
      elevation: backgroundColor != null ? 0 : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A small icon-box around the back affordance, in the same surface
/// color as the Home screen's category icon boxes — gives it a visible
/// shape of its own so it still reads as a tappable control on a flat,
/// page-colored bar (where a bare icon has nothing but its own color to
/// stand on).
class _GlassBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const _GlassBackButton({required this.onPressed, required this.iconColor});

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    // AppBar forces a tight box on the leading slot (full toolbar height
    // x leading width) — without this Center, that tight constraint
    // clamps the Container below up to the slot's own size instead of
    // letting it stay at its real 20x20.
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_size / 2),
          child: Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.categoryCardSurface,
              borderRadius: BorderRadius.circular(_size / 2),
            ),
            // Not Icon(Icons.arrow_back) — BackButtonIcon auto-mirrors
            // for RTL locales (Arabic), where "back" points right.
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: 20),
              child: const BackButtonIcon(),
            ),
          ),
        ),
      ),
    );
  }
}
