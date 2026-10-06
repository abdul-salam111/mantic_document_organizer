import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/background/auto_import_service.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/local_storage/local_storage_exports.dart';

/// One-time, first-login prompt asking permission to automatically find and
/// organize documents in the background -- replaces the old "Find your
/// documents" popup as the first-login trigger (see NavbarView). Granting
/// here only kicks off AutoImportService's scan; it never creates a
/// document itself -- the user still reviews/confirms on
/// BulkImportReviewView once the scan (surfaced via a notification) finds
/// something.
class AutoImportConsentSheet {
  const AutoImportConsentSheet._();

  static Future<void> show(BuildContext context) async {
    await storage.setValues(StorageKeys.hasSeenBulkImportPrompt, 'true');
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _AutoImportConsentContent(),
    );
  }
}

class _AutoImportConsentContent extends StatelessWidget {
  const _AutoImportConsentContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.travel_explore_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Automatically organize your documents?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dockitly can scan your photos and files in the background to '
            'find and organize documents for you. You always review and '
            "confirm what's imported before anything is added — this just "
            'looks for candidates. Requires internet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(sl<AutoImportService>().onPermissionGranted());
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Allow'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
