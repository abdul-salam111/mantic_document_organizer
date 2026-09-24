import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'document_chips.dart';

/// Row rendering for a single [DocumentItem] — icon, title, file count +
/// relative time, tags, an expiry badge when applicable, and a favorite
/// toggle. Shared by every screen listing documents in a list layout
/// (category_documents, favorites, ...) instead of each screen carrying
/// its own copy.
class DocumentListTile extends StatelessWidget {
  final DocumentItem document;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.accentColor,
    required this.onTap,
    required this.onToggleFavorite,
  });

  bool get _showExpiryChip =>
      document.isExpirable && document.expiryDate != null;

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
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: .center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: .circular(11),
              ),
              child: FaIcon(document.icon, size: 19, color: accentColor),
            ),
            widthBox(12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.bodyMedium.copyWith(fontWeight: .w600),
                  ),
                  heightBox(4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.document,
                        size: 12,
                        color: context.textSecondary,
                      ),
                      widthBox(4),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).fileCount(document.filePaths.length),
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      widthBox(8),
                      Text(
                        '•',
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      widthBox(8),
                      Text(
                        document.createdAt.timeAgo,
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (document.tags.isNotEmpty || _showExpiryChip) ...[
                    heightBox(8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_showExpiryChip)
                          ExpiryChip(expiryDate: document.expiryDate!),
                        for (final tag in document.tags) TagChip(tag: tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: .compact,
              tooltip: document.isFavorite
                  ? AppLocalizations.of(context).removeFromFavorites
                  : AppLocalizations.of(context).addToFavorites,
              icon: Icon(
                document.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                size: 20,
                color: document.isFavorite
                    ? context.errorAccent
                    : context.textSecondary,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
