import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';

/// Compact card rendering for a single [DocumentItem] — the grid-layout
/// counterpart to [DocumentListTile], for screens with a grid/list view
/// toggle (favorites, ...).
class DocumentGridTile extends StatelessWidget {
  final DocumentItem document;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const DocumentGridTile({
    super.key,
    required this.document,
    required this.accentColor,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(14),
      onTap: onTap,
      child: Container(
        padding: const .all(12),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(14),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: .center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: .circular(10),
                  ),
                  child: FaIcon(document.icon, size: 17, color: accentColor),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: .circular(20),
                  onTap: onToggleFavorite,
                  child: Padding(
                    padding: const .all(4),
                    child: Icon(
                      document.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                      size: 18,
                      color: document.isFavorite
                          ? context.errorAccent
                          : context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            heightBox(10),
            Text(
              document.title,
              maxLines: 2,
              overflow: .ellipsis,
              style: context.bodyMedium.copyWith(fontWeight: .w600),
            ),
            heightBox(4),
            Text(
              document.category,
              maxLines: 1,
              overflow: .ellipsis,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
            const Spacer(),
            heightBox(6),
            Row(
              children: [
                Icon(Iconsax.document, size: 11, color: context.textSecondary),
                widthBox(4),
                Text(
                  AppLocalizations.of(
                    context,
                  ).fileCount(document.filePaths.length),
                  style: context.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
