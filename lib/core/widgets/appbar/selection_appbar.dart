import 'package:flutter/material.dart';

import '../../localization/localization_exports.dart';
import '../../theme/theme_exports.dart';

/// Replaces a screen's normal app bar while a multi-select list has one or
/// more items selected (long-press an item to enter this mode) — shared by
/// every screen with a long-press-to-select-then-bulk-delete list
/// (manage_categories, document_viewer's page list, category_documents)
/// instead of each one carrying its own copy.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const SelectionAppBar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.primary,
      iconTheme: IconThemeData(color: context.white),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context).selectedCount(count),
        style: context.bodyLarge.copyWith(
          color: context.white,
          fontWeight: .bold,
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
