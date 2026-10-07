import 'dart:async';

import '../constants/constants_exports.dart';
import '../local_storage/local_storage_exports.dart';
import '../notifications/notifications_exports.dart';
import '../../features/bulk_import/bulk_import_exports.dart';
import '../../routes/routes_exports.dart';

/// Drives every scan that happens outside the manual "Find my documents"
/// button inside the old Bulk Import dialog flow -- the one-time automatic
/// scan right after a user grants photo/file access (see
/// AutoImportConsentSheet), its startup-recovery counterpart, and the
/// repeatable "Find more documents" entry point in Profile. All three run
/// in-app, in the background (the app stays open; this is not a true
/// OS-level service), progress surfaced only through a notification so the
/// rest of the app stays fully usable while it runs. None of them ever
/// create a document directly -- they only get the user to
/// BulkImportReviewView, the single "never save without confirmation"
/// screen every entry point shares.
class AutoImportService {
  AutoImportService({
    required BulkImportViewModel Function() createViewModel,
    required AutoImportNotifications notifications,
  }) : _createViewModel = createViewModel,
       _notifications = notifications {
    _notifications.onReviewTapped = _openReview;
  }

  final BulkImportViewModel Function() _createViewModel;
  final AutoImportNotifications _notifications;
  BulkImportViewModel? _pendingReviewViewModel;
  bool _running = false;

  /// Startup-recovery path (see main.dart): permission may have been
  /// granted in a previous session whose scan didn't get to finish. Never
  /// prompts for permission -- a source that isn't already (passively)
  /// granted is simply skipped rather than surprising the user with a
  /// permission dialog, or (for filesystem access) silently launching the
  /// device Settings app, with no action taken this session to justify it.
  Future<void> maybeRunInitialScan() async {
    if (!AppConstants.bulkImportEnabled || _running) return;
    if ((await storage.readValues(StorageKeys.hasRunInitialAutoImport)) ==
        'true') {
      return;
    }
    // Critical gate: on a fresh install that hasn't been through the
    // consent sheet yet, nothing is granted -- this path must NOT spend
    // the one-shot flag in that case, or the real, permission-prompting
    // scan (onPermissionGranted, fired by the consent sheet's "Allow")
    // would find the flag already consumed and never get to run at all.
    final vm = _createViewModel();
    if (!await vm.hasAnyDiscoveryPermission()) {
      vm.dispose();
      return;
    }
    await _markOneShotFlag();
    await _runScan(vm, allowPermissionPrompts: false, restrictToRecentWindow: true);
  }

  /// Called by AutoImportConsentSheet right after the user grants
  /// permission, so the scan starts immediately instead of waiting for the
  /// next app launch. Permission prompts are fine here -- this is a direct
  /// continuation of the user's own "Allow" tap.
  Future<void> onPermissionGranted() async {
    if (!AppConstants.bulkImportEnabled || _running) return;
    if ((await storage.readValues(StorageKeys.hasRunInitialAutoImport)) ==
        'true') {
      return;
    }
    await _markOneShotFlag();
    await _runScan(
      _createViewModel(),
      allowPermissionPrompts: true,
      restrictToRecentWindow: true,
    );
  }

  /// Profile -> "Find more documents": a direct, explicit, repeatable user
  /// request, unlike the two one-time paths above -- never gated by the
  /// one-shot flag, and never limited to the last ~12 months the way the
  /// automatic first scan is -- the user tapped this expecting it to look
  /// through their entire history, not just recent files, all in one pass.
  Future<void> runManualScan() async {
    if (!AppConstants.bulkImportEnabled || _running) return;
    await _runScan(
      _createViewModel(),
      allowPermissionPrompts: true,
      restrictToRecentWindow: false,
    );
  }

  // One real attempt per install, set before scanning starts -- a crash
  // mid-scan must not retry on every subsequent launch. Any further scan
  // from these two one-time paths is the user-initiated runManualScan().
  Future<void> _markOneShotFlag() =>
      storage.setValues(StorageKeys.hasRunInitialAutoImport, 'true');

  Future<void> _runScan(
    BulkImportViewModel vm, {
    required bool allowPermissionPrompts,
    required bool restrictToRecentWindow,
  }) async {
    _running = true;
    var lastShown = DateTime.fromMillisecondsSinceEpoch(0);
    void onProgress() {
      final now = DateTime.now();
      if (now.difference(lastShown) < const Duration(milliseconds: 800)) {
        return;
      }
      lastShown = now;
      // No fixed budget any more (the scan is deliberately uncapped) --
      // `totalEstimate: 0` renders as an indeterminate progress bar instead
      // of a misleading "N of 150" that doesn't reflect the real total.
      unawaited(
        _notifications.showScanning(examined: vm.scanExamined, totalEstimate: 0),
      );
    }

    vm.addListener(onProgress);
    try {
      await _notifications.showScanning(examined: 0, totalEstimate: 0);
      await vm.discoverAll(
        allowPermissionPrompts: allowPermissionPrompts,
        restrictToRecentWindow: restrictToRecentWindow,
      );
    } finally {
      vm.removeListener(onProgress);
      _running = false;
    }

    if (vm.candidates.isEmpty) {
      await _notifications.dismissQuiet();
      vm.dispose();
      return;
    }
    // A still-unreviewed batch from an earlier scan would otherwise leak
    // its staging session (and be silently unreachable once overwritten).
    _pendingReviewViewModel?.dispose();
    _pendingReviewViewModel = vm;
    await _notifications.showFound(vm.candidates.length);
  }

  void _openReview() {
    final vm = _pendingReviewViewModel;
    if (vm == null) return;
    _pendingReviewViewModel = null;
    AppNavigator.pushNamed(RouteNames.bulkImportReview, extra: vm);
  }
}
