import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'document_chips.dart';
import 'document_cover_thumbnail.dart';

/// Row rendering for a single [DocumentItem] — cover thumbnail, a
/// category-colored accent bar, title, file count + relative time, tags,
/// an expiry badge when applicable, and a favorite toggle. Shared by every
/// screen listing documents in a list layout (category_documents,
/// favorites, ...) instead of each screen carrying its own copy.
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
      borderRadius: .circular(16),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(16),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // A thin category-colored bar spanning the tile's full height, so
        // its category reads at a glance without parsing the icon/text —
        // IntrinsicHeight lets the Row's children stretch to match it.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const .all(8),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      DocumentCoverThumbnail(
                        document: document,
                        color: accentColor,
                        width: 76,
                        height: 76,
                        borderRadius: 12,
                        iconSize: 26,
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
                              style: context.bodyMedium.copyWith(
                                fontWeight: .w700,
                              ),
                            ),
                            heightBox(6),
                            _MetaLine(
                              text:
                                  '${AppLocalizations.of(context).fileCount(document.filePaths.length)} · ${document.createdAt.timeAgoShort}',
                            ),
                            if (document.tags.isNotEmpty ||
                                _showExpiryChip) ...[
                              heightBox(8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (_showExpiryChip)
                                    ExpiryChip(
                                      expiryDate: document.expiryDate!,
                                    ),
                                  for (final tag in document.tags)
                                    TagChip(tag: tag),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      widthBox(4),
                      _FavoriteButton(
                        isFavorite: document.isFavorite,
                        onTap: onToggleFavorite,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single line of secondary metadata — used instead of a literal "•"
/// character (inconsistent baseline/weight across fonts) for separating
/// clauses.
class _MetaLine extends StatelessWidget {
  final String text;

  const _MetaLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: .ellipsis,
      style: context.labelSmall.copyWith(color: context.textSecondary),
    );
  }
}

/// A proper circular tap target (not a bare icon) that fills in softly
/// when favorited.
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite
          ? AppLocalizations.of(context).removeFromFavorites
          : AppLocalizations.of(context).addToFavorites,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(18),
        child: Container(
          width: 36,
          height: 36,
          alignment: .center,
          decoration: BoxDecoration(
            color: isFavorite
                ? context.errorAccent.withValues(alpha: 0.1)
                : context.transparent,
            shape: .circle,
          ),
          child: Icon(
            isFavorite ? Iconsax.heart5 : Iconsax.heart,
            size: 19,
            color: isFavorite ? context.errorAccent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
