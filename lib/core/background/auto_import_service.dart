import 'dart:async';

import '../constants/constants_exports.dart';
import '../local_storage/local_storage_exports.dart';
import '../notifications/notifications_exports.dart';
import '../../features/bulk_import/bulk_import_exports.dart';
import '../../routes/routes_exports.dart';

/// Drives the one-time, automatic "import everything important" scan right
/// after a user grants photo/file access (see AutoImportConsentSheet) --
/// runs in-app, in the background (the app stays open; this is not a true
/// OS-level service), progress surfaced only through a notification so the
/// rest of the app stays fully usable while it runs. Never creates a
/// document itself -- it only gets the user to BulkImportReviewView, the
/// same "never save without confirmation" screen the manual "Find more
/// documents" entry point already uses.
class AutoImportService {
  AutoImportService({
    required BulkImportViewModel Function() createViewModel,
    required AutoImportNotifications notifications,
  }) : _createViewModel = createViewModel,
       _notifications = notifications {
    _notifications.onReviewTapped = _openReview;
  }

  /// Generous cap for this one-time pass only -- deliberately higher than
  /// [BulkImportViewModel.maxCandidates] (used by the manual, repeatable
  /// "Find more documents" flow), since this is meant to be a genuine
  /// "find everything important" first pass rather than one capped batch.
  static const int initialScanCandidateCeiling = 100;

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
    await _runScan(vm, allowPermissionPrompts: false);
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
    await _runScan(_createViewModel(), allowPermissionPrompts: true);
  }

  Future<void> _runScan(
    BulkImportViewModel vm, {
    required bool allowPermissionPrompts,
  }) async {
    _running = true;
    // One real attempt per install, set before scanning starts -- a crash
    // mid-scan must not retry on every subsequent launch. Any further scan
    // is the existing, user-initiated "Find more documents" entry point.
    await storage.setValues(StorageKeys.hasRunInitialAutoImport, 'true');
    var lastShown = DateTime.fromMillisecondsSinceEpoch(0);
    void onProgress() {
      final now = DateTime.now();
      if (now.difference(lastShown) < const Duration(milliseconds: 800)) {
        return;
      }
      lastShown = now;
      unawaited(
        _notifications.showScanning(
          examined: vm.scanExamined,
          totalEstimate: BulkImportViewModel.maxExaminedPerScan * 2,
        ),
      );
    }

    vm.addListener(onProgress);
    try {
      await _notifications.showScanning(examined: 0, totalEstimate: 0);
      await vm.discoverAll(
        maxCandidatesOverride: initialScanCandidateCeiling,
        allowPermissionPrompts: allowPermissionPrompts,
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
