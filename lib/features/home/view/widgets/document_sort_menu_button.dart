import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';

/// Sort-order menu shared by every screen listing [DocumentItem]s
/// (category_documents, favorites, ...) — same options, same ordering,
/// so it isn't redefined per screen.
class DocumentSortMenuButton extends StatelessWidget {
  final DocumentSort selected;
  final ValueChanged<DocumentSort> onSelected;

  const DocumentSortMenuButton({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DocumentSort>(
      tooltip: AppLocalizations.of(context).sortBy,
      icon: Icon(Iconsax.sort, color: context.white),
      onSelected: onSelected,
      itemBuilder: (context) => [
        _item(
          context,
          value: DocumentSort.newest,
          label: AppLocalizations.of(context).sortNewestFirst,
        ),
        _item(
          context,
          value: DocumentSort.oldest,
          label: AppLocalizations.of(context).sortOldestFirst,
        ),
        _item(
          context,
          value: DocumentSort.nameAz,
          label: AppLocalizations.of(context).sortNameAZ,
        ),
      ],
    );
  }

  PopupMenuItem<DocumentSort> _item(
    BuildContext context, {
    required DocumentSort value,
    required String label,
  }) {
    final isSelected = selected == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            Iconsax.tick_circle,
            size: 18,
            color: isSelected ? context.primary : context.transparent,
          ),
          widthBox(10),
          Text(
            label,
            style: context.bodyMedium.copyWith(
              fontWeight: isSelected ? .w600 : .normal,
            ),
          ),
        ],
      ),
    );
  }
}
