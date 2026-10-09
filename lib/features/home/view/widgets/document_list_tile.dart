import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import 'document_chips.dart';
import 'document_cover_thumbnail.dart';
import 'document_selection_badge.dart';

/// Row rendering for a single [DocumentItem] — cover thumbnail, a
/// category-colored accent bar, title, file count + relative time, an
/// expiry badge when applicable, and a favorite toggle. Shared by every
/// screen listing documents in a list layout (category_documents,
/// favorites, ...) instead of each screen carrying its own copy.
class DocumentListTile extends StatelessWidget {
  final DocumentItem document;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  /// Long-press-to-select — all three default to "not selectable" so every
  /// existing screen using this tile (home, favorites, ...) keeps working
  /// unchanged; only a screen that wires these up (category_documents) gets
  /// the selection UI.
  final VoidCallback? onLongPress;
  final bool isSelecting;
  final bool isSelected;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.accentColor,
    required this.onTap,
    required this.onToggleFavorite,
    this.onLongPress,
    this.isSelecting = false,
    this.isSelected = false,
  });

  bool get _showExpiryChip =>
      document.isExpirable && document.expiryDate != null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.categoryCardSurface,
          borderRadius: .circular(16),
          border: Border.all(
            color: isSelected ? context.primary : context.border,
            width: isSelected ? 2 : 1,
          ),
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
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          children: [
                            DocumentCoverThumbnail(
                              document: document,
                              color: accentColor,
                              width: 76,
                              height: 76,
                              borderRadius: 12,
                              iconSize: 26,
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: PendingSyncBadge(
                                documentId: document.id,
                                size: 21,
                              ),
                            ),
                            if (isSelecting)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DocumentSelectionBadge(
                                    isSelected: isSelected,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                            if (_showExpiryChip) ...[
                              heightBox(8),
                              ExpiryChip(expiryDate: document.expiryDate!),
                            ],
                          ],
                        ),
                      ),
                      widthBox(4),
                      // Hidden rather than disabled while selecting — tapping
                      // a star mid-selection reads as "favorite this one"
                      // more than "select it", so it's removed as a tap
                      // target entirely instead of just no-op'd.
                      if (!isSelecting)
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
