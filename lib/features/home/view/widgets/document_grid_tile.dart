import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'document_cover_thumbnail.dart';

/// Image-forward card rendering for a single [DocumentItem] — the
/// grid-layout counterpart to [DocumentListTile], for screens with a
/// grid/list view toggle (favorites, ...). The cover spans the card's full
/// width so it reads as a genuine preview rather than a small icon avatar;
/// tags/expiry stay list-only, where there's room for them without risking
/// overflow in a fixed-height grid cell. The cover's height is a fraction
/// of the available width ([_coverAspectRatio]), not a fixed pixel value —
/// since the grid cell itself is a fixed fraction of screen width (see
/// every consumer's `childAspectRatio: 0.85`), this keeps the image-to-text
/// proportion — and therefore how much room is left for text below it —
/// consistent across device sizes instead of a fixed height eating a
/// disproportionate share of a narrow cell's limited height budget.
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

  static const double _coverAspectRatio = 1.6;

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
        child: Column(
          crossAxisAlignment: .start,
          children: [
            // Flush to the card's own edges (no inset) so the cover reads as
            // a real preview filling the card, not a small image floating in
            // a border of whitespace — the outer Container's own clip
            // rounds just its top corners since the cover sits exactly at
            // the card's top/left/right.
            AspectRatio(
              aspectRatio: _coverAspectRatio,
              child: Stack(
                children: [
                  DocumentCoverThumbnail(
                    document: document,
                    color: accentColor,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                    iconSize: 30,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FloatingFavoriteButton(
                      isFavorite: document.isFavorite,
                      onTap: onToggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.bodyMedium.copyWith(fontWeight: .w700),
                    ),
                    heightBox(6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: .circle,
                          ),
                        ),
                        widthBox(6),
                        Expanded(
                          child: Text(
                            document.category,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: context.labelSmall.copyWith(
                              color: context.textSecondary,
                              fontWeight: .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${AppLocalizations.of(context).fileCount(document.filePaths.length)} · ${document.createdAt.timeAgoShort}',
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sits on top of the cover image, so its background needs to hold up
/// against any photo content behind it — a translucent scrim rather than
/// the plain transparent-until-favorited style [DocumentListTile] uses,
/// which relies on sitting on a flat card background instead.
class _FloatingFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FloatingFavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite
          ? AppLocalizations.of(context).removeFromFavorites
          : AppLocalizations.of(context).addToFavorites,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(15),
        child: Container(
          width: 30,
          height: 30,
          alignment: .center,
          decoration: BoxDecoration(
            color: context.black.withValues(alpha: 0.45),
            shape: .circle,
          ),
          child: Icon(
            isFavorite ? Iconsax.heart5 : Iconsax.heart,
            size: 16,
            color: isFavorite ? context.errorAccent : context.white,
          ),
        ),
      ),
    );
  }
}
