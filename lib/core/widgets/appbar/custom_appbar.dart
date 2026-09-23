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

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: context.white),
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
      title: Text(
        title,
        style: context.bodyLarge.copyWith(
          color: context.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: context.primary,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
