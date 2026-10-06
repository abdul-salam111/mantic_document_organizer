import 'package:flutter/material.dart';

import '../../../../core/theme/theme_exports.dart';

/// The checkmark-circle overlay shown on a document's cover thumbnail while
/// a list is in multi-select mode — a filled check when selected, an empty
/// outline otherwise (so an unselected-but-selectable tile still reads as
/// "selectable", not just blank). Shared by [DocumentListTile] and
/// [DocumentGridTile] so both tiles' selection UI stays visually identical.
class DocumentSelectionBadge extends StatelessWidget {
  final bool isSelected;

  const DocumentSelectionBadge({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      if (isSelected)
        ColoredBox(color: context.primary.withValues(alpha: 0.16)),
      Positioned(
        top: 4,
        right: 4,
        child: Container(
          width: 20,
          height: 20,
          alignment: .center,
          decoration: BoxDecoration(
            color: isSelected
                ? context.primary
                : context.black.withValues(alpha: 0.35),
            shape: .circle,
            border: isSelected
                ? null
                : Border.all(color: context.white, width: 1.5),
          ),
          child: isSelected
              ? Icon(Icons.check_rounded, size: 13, color: context.white)
              : null,
        ),
      ),
    ],
  );
}
