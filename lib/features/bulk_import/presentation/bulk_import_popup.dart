import 'package:flutter/material.dart';
import '../../../core/constants/constants_exports.dart';
import '../../../routes/routes_exports.dart';
import 'bulk_import_flow_content.dart';
import 'viewmodel/bulk_import_viewmodel.dart';

/// Shows the Bulk Import flow as a compact dialog rather than a full page --
/// used both for the one-time prompt right after a user's first login, and
/// for Profile's "Find more documents" re-entry point, so there's exactly
/// one UI to maintain.
class BulkImportPopup {
  const BulkImportPopup._();

  static Future<void> show(BuildContext context) async {
    if (!AppConstants.bulkImportEnabled) return;
    final found = await showDialog<BulkImportViewModel>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BulkImportFlowContent(
            onFound: (vm) => Navigator.of(dialogContext).pop(vm),
            onDismiss: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
    if (found != null) {
      AppNavigator.pushNamed(RouteNames.bulkImportReview, extra: found);
    }
  }
}
