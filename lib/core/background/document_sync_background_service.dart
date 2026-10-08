import 'dart:async';

import '../database/database_exports.dart';
import '../notifications/notifications_exports.dart';
import '../../features/backup/data/services/document_sync_service.dart';
import '../../features/backup/domain/entities/sync_progress.dart';
import '../../features/categories/domain/usecases/category_usecases.dart';
import '../../features/documents/domain/usecases/document_usecases.dart';
import '../../routes/routes_exports.dart';

/// Drives a backup/sync run in the background (the app stays open; this is
/// not a true OS-level service) from Profile -> Sync & backup's "Back up
/// now"/"Retry" buttons, surfacing progress and the final result only
/// through a notification -- same pattern as AutoImportService -- so the
/// user doesn't have to stay on BackupSetupPage and watch its status card
/// to find out when a sync finishes (or fails).
class DocumentSyncBackgroundService {
  DocumentSyncBackgroundService({
    required DocumentSyncService syncService,
    required AppDatabase database,
    required DocumentUseCases documents,
    required CategoryUseCases categories,
    required DocumentSyncNotifications notifications,
  }) : _syncService = syncService,
       _database = database,
       _documents = documents,
       _categories = categories,
       _notifications = notifications {
    _notifications.onOpenTapped = _openBackupSetup;
  }

  final DocumentSyncService _syncService;
  final AppDatabase _database;
  final DocumentUseCases _documents;
  final CategoryUseCases _categories;
  final DocumentSyncNotifications _notifications;

  /// Keyed by spaceId -- see DocumentSyncService's matching field for why
  /// a single global flag was wrong here (it let one space's sync being
  /// in-flight silently swallow another space's "Sync now" tap).
  final Set<String> _runningSpaceIds = {};

  /// [queueExistingDocuments] matches "Back up now"'s existing behavior of
  /// queuing every current document before syncing, so a first backup (or
  /// one after being off for a while) doesn't rely solely on documents
  /// that happened to be mutated since the outbox was last drained.
  /// "Retry" (a failed run's own button) omits it, same as before.
  Future<void> runBackup({
    required String token,
    required String spaceId,
    bool queueExistingDocuments = false,
  }) => runSpaceSync(
    token: token,
    spaceId: spaceId,
    isPersonalSpace: true,
    queueExistingDocuments: queueExistingDocuments,
  );

  /// Generalizes [runBackup] to also drive a single shared category's
  /// space -- same progress/notification pattern, just scoped to that one
  /// space (see [DocumentSyncService.sync]'s [isPersonalSpace]). Used by the
  /// Share screen's "Sync now" action and right after a successful
  /// invitation/join-link accept.
  Future<void> runSpaceSync({
    required String token,
    required String spaceId,
    required bool isPersonalSpace,
    String? newCategoryRole,
    bool queueExistingDocuments = false,
  }) async {
    if (!_runningSpaceIds.add(spaceId)) return;
    var lastShown = DateTime.fromMillisecondsSinceEpoch(0);
    void onProgress() {
      final p = _syncService.progress.value;
      if (!p.isActive) return;
      final now = DateTime.now();
      if (now.difference(lastShown) < const Duration(milliseconds: 800)) {
        return;
      }
      lastShown = now;
      unawaited(
        _notifications.showSyncing(
          current: p.current,
          total: p.total,
          label: p.itemLabel ?? _labelFor(p.stage),
        ),
      );
    }

    _syncService.progress.addListener(onProgress);
    try {
      await _notifications.showSyncing(current: 0, total: 0, label: 'Starting backup…');
      if (queueExistingDocuments) {
        await _database.queueExistingDocumentsForSync();
      }
      await _syncService.sync(
        token: token,
        spaceId: spaceId,
        isPersonalSpace: isPersonalSpace,
        newCategoryRole: newCategoryRole,
      );
      // Home/Manage Categories keep in-memory caches -- reload both after a
      // sync so anything pulled (a restored document, or a brand-new shared
      // category on a joining member's first sync) is visible without
      // reopening the app.
      await _categories.init();
      await _documents.init();
      await _notifications.showCompleted();
    } catch (_) {
      final message =
          _syncService.progress.value.errorMessage ??
          'Could not finish syncing. Tap to try again.';
      await _notifications.showFailed(message);
    } finally {
      _syncService.progress.removeListener(onProgress);
      _runningSpaceIds.remove(spaceId);
    }
  }

  String _labelFor(SyncStage stage) => switch (stage) {
    SyncStage.preparing => 'Preparing…',
    SyncStage.categories => 'Syncing categories…',
    SyncStage.documents => 'Syncing documents…',
    SyncStage.idle || SyncStage.completed || SyncStage.failed => 'Syncing…',
  };

  void _openBackupSetup() => AppNavigator.pushNamed(RouteNames.backupSetup);
}
