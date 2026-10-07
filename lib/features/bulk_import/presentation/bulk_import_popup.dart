import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/background/auto_import_service.dart';
import '../../../core/constants/constants_exports.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';

/// Profile -> "Find more documents": confirms once that Dockitly can look
/// for documents, then hands off to AutoImportService.runManualScan() and
/// returns immediately -- the scan itself runs in the background (progress
/// and completion surfaced only via a notification), so the user never has
/// to wait on a dialog, and can keep using the rest of the app right away.
class BulkImportPopup {
  const BulkImportPopup._();

  static Future<void> show(BuildContext context) async {
    if (!AppConstants.bulkImportEnabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _BulkImportDialog(),
    );
    if (confirmed != true) return;
    AppToastsUtils.info('Looking for documents in the background…');
    unawaited(sl<AutoImportService>().runManualScan());
  }
}

class _BulkImportDialog extends StatelessWidget {
  const _BulkImportDialog();

  static const _highlights = [
    (
      Icons.bolt_outlined,
      'Runs quietly in the background -- keep using the app as normal',
    ),
    (
      Icons.notifications_none_rounded,
      "You'll get a notification the moment it's done",
    ),
    (
      Icons.fact_check_outlined,
      'Nothing is added to your library until you review and confirm it',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: .circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: .min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: .12),
                shape: .circle,
              ),
              child: Icon(
                Icons.travel_explore_outlined,
                size: 32,
                color: context.primary,
              ),
            ),
            heightBox(18),
            Text(
              'Find more documents',
              textAlign: .center,
              style: context.titleLarge.copyWith(fontWeight: .w700),
            ),
            heightBox(8),
            Text(
              'Dockitly will look for documents in your photos and files '
              'that aren\'t in your library yet.',
              textAlign: .center,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            heightBox(20),
            for (final (icon, text) in _highlights) ...[
              _HighlightRow(icon: icon, text: text),
              heightBox(12),
            ],
            heightBox(8),
            CustomButton(
              text: 'Find documents',
              icon: Icons.travel_explore_outlined,
              iconSize: 18,
              radius: 14,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            heightBox(4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not now',
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  fontWeight: .w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: context.primary.withValues(alpha: .1),
            shape: .circle,
          ),
          child: Icon(icon, size: 15, color: context.primary),
        ),
        widthBox(12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: context.bodySmall.copyWith(
                color: context.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
