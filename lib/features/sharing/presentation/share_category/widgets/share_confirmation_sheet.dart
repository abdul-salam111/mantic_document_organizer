import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';

/// First-time-share-only confirmation (see
/// docs/space_sharing_ux_plan.txt §2, Step 1) -- shown before anything is
/// created server-side, since turning a category into a shared space is a
/// one-way-ish door. Returns `true` if the owner confirmed.
class ShareConfirmationSheet extends StatelessWidget {
  final String categoryName;

  const ShareConfirmationSheet({super.key, required this.categoryName});

  static Future<bool> show(BuildContext context, {required String categoryName}) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareConfirmationSheet(categoryName: categoryName),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            heightBox(20),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.share, color: context.primary, size: 26),
            ),
            heightBox(16),
            Text(
              'Share $categoryName?',
              textAlign: TextAlign.center,
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            heightBox(8),
            Text(
              'Anyone you invite will be able to see every document in this category.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            heightBox(24),
            CustomButton(
              text: 'Share category',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            heightBox(8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
