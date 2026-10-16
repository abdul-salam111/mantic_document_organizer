import 'dart:async';

import '../notifications/notifications_exports.dart';
import '../utils/utils_exports.dart';
import '../../features/bulk_import/bulk_import_exports.dart';
import '../../routes/routes_exports.dart';

/// Runs `BulkImportViewModel.seedFromSharedFiles()` detached from whatever
/// screen started it -- picking files from Profile's "Import documents"
/// (camera/gallery/file) hands the viewmodel off here and the caller moves
/// on immediately, so OCR + AI grouping never blocks the rest of the app.
/// Progress is surfaced through a notification, same in-app-background
/// approach as [AutoImportService]/[BulkImportCommitService], but the
/// moment grouping finishes this opens the review screen directly instead
/// of waiting for a notification tap -- the user already asked for this by
/// picking files, so there's nothing to confirm first the way there is for
/// [AutoImportService]'s passive, unprompted scan.
class BulkImportSeedService {
  BulkImportSeedService({required BulkImportSeedNotifications notifications})
    : _notifications = notifications;

  final BulkImportSeedNotifications _notifications;

  /// Fire-and-forget by design -- the caller has already handed off
  /// ownership of [vm] and moves on without waiting.
  void runInBackground(BulkImportViewModel vm, List<String> paths) {
    unawaited(_seed(vm, paths));
  }

  Future<void> _seed(BulkImportViewModel vm, List<String> paths) async {
    // Same 800ms throttle as AutoImportService's scan loop -- OCR over a
    // batch of picked files is many fast per-file checks, worth throttling
    // so the notification isn't rewritten on every single one.
    var lastShown = DateTime.fromMillisecondsSinceEpoch(0);
    void onProgress() {
      final now = DateTime.now();
      if (now.difference(lastShown) < const Duration(milliseconds: 800)) {
        return;
      }
      lastShown = now;
      unawaited(
        _notifications.showOrganizing(
          examined: vm.scanExamined,
          total: paths.length,
        ),
      );
    }

    vm.addListener(onProgress);
    bool found;
    try {
      await _notifications.showOrganizing(examined: 0, total: paths.length);
      found = await vm.seedFromSharedFiles(paths);
    } finally {
      vm.removeListener(onProgress);
    }
    await _notifications.dismissQuiet();

    if (!found) {
      AppToastsUtils.error(vm.notice ?? 'Could not organize these files.');
      vm.dispose();
      return;
    }
    AppNavigator.pushNamed(RouteNames.bulkImportReview, extra: vm);
  }
}
