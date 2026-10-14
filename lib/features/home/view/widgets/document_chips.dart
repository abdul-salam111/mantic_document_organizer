import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';

/// Overdue/soon/later, shared by [ExpiryChip] and Home's Expiring Soon
/// preview cards (their left accent bar) so both read urgency the same
/// way instead of each picking their own thresholds.
Color expiryUrgencyColor(BuildContext context, DateTime expiryDate) {
  final daysLeft = expiryDate.difference(DateTime.now()).inDays;
  return daysLeft < 0
      ? context.errorAccent
      : daysLeft <= 30
      ? context.warning
      : context.textSecondary;
}

/// Color-coded by urgency (overdue/soon/later) — shared by
/// [DocumentListTile] and document_viewer's info panel.
class ExpiryChip extends StatelessWidget {
  final DateTime expiryDate;

  const ExpiryChip({super.key, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final chipColor = expiryUrgencyColor(context, expiryDate);
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: .circular(20),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(Iconsax.timer_1, size: 11, color: chipColor),
          widthBox(4),
          // Flexible + ellipsis rather than an unbounded Text — this chip
          // is also used in narrow contexts (Home's Expiring Soon preview
          // cards), where the full "Expires on <date>" string doesn't
          // always fit.
          Flexible(
            child: Text(
              AppLocalizations.of(context).expiresOn(expiryDate.formatted),
              maxLines: 1,
              overflow: .ellipsis,
              style: context.labelSmall.copyWith(
                color: chipColor,
                fontWeight: .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared by [DocumentListTile] and document_viewer's info panel.
class TagChip extends StatelessWidget {
  final String tag;

  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: .circular(20),
        border: Border.all(color: context.border),
      ),
      child: Text(
        tag,
        style: context.labelSmall.copyWith(color: context.textSecondary),
      ),
    );
  }
}
