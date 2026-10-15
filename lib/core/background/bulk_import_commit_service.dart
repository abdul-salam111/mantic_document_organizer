import 'dart:async';

import '../notifications/notifications_exports.dart';
import '../../features/bulk_import/bulk_import_exports.dart';
import '../../routes/routes_exports.dart';

/// Runs `BulkImportViewModel.commit()` detached from whatever screen
/// started it -- tapping "Import" on BulkImportReviewView hands the
/// viewmodel off here and leaves immediately, so saving never blocks the
/// rest of the app. Progress and the final result are surfaced only
/// through a notification, same in-app-background approach as
/// [AutoImportService] uses for discovery.
class BulkImportCommitService {
  BulkImportCommitService({
    required BulkImportCommitNotifications notifications,
  }) : _notifications = notifications {
    _notifications.onReviewTapped = _openReview;
  }

  final BulkImportCommitNotifications _notifications;
  BulkImportViewModel? _pendingReviewViewModel;

  /// Fire-and-forget by design -- the caller (the review screen) has
  /// already handed off ownership of [vm] and moves on without waiting.
  void runInBackground(BulkImportViewModel vm) {
    unawaited(_commit(vm));
  }

  Future<void> _commit(BulkImportViewModel vm) async {
    // Unlike AutoImportService's scan loop (many fast per-asset checks,
    // worth throttling), each commit step does real file + database work
    // -- naturally paced slower, and the final showResult() below always
    // overwrites this notification with the accurate count regardless, so
    // an update per document is cheap and never leaves a stale progress
    // number on screen.
    void onProgress() {
      unawaited(
        _notifications.showImporting(
          completed: vm.importCompleted,
          total: vm.importTotal,
        ),
      );
    }

    vm.addListener(onProgress);
    final BulkImportResult result;
    try {
      await _notifications.showImporting(completed: 0, total: vm.selectedCount);
      result = await vm.commit();
    } finally {
      vm.removeListener(onProgress);
    }

    if (result.failures.isEmpty) {
      await _notifications.showResult(
        imported: result.imported,
        failedCount: 0,
      );
      vm.dispose();
      return;
    }
    // A still-unreviewed failure batch from an earlier commit would
    // otherwise leak its staging session (and become silently
    // unreachable once overwritten).
    _pendingReviewViewModel?.dispose();
    _pendingReviewViewModel = vm;
    await _notifications.showResult(
      imported: result.imported,
      failedCount: result.failures.length,
    );
  }

  void _openReview() {
    final vm = _pendingReviewViewModel;
    if (vm == null) return;
    _pendingReviewViewModel = null;
    AppNavigator.pushNamed(RouteNames.bulkImportReview, extra: vm);
  }
}
