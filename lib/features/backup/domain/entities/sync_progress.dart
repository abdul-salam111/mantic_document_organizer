/// What `DocumentSyncService` is currently doing, for UI consumption.
enum SyncStage { idle, preparing, categories, documents, completed, failed }

/// Which way data is moving during [SyncStage.documents].
enum SyncDirection { none, upload, download }

/// A snapshot of backup-sync progress, reported by `DocumentSyncService`
/// through its `progress` notifier so the setup/profile UI can show more
/// than a bare spinner while uploads/downloads run.
class SyncProgress {
  final SyncStage stage;
  final SyncDirection direction;
  final int current;
  final int total;
  final String? itemLabel;
  final String? errorMessage;

  const SyncProgress({
    this.stage = SyncStage.idle,
    this.direction = SyncDirection.none,
    this.current = 0,
    this.total = 0,
    this.itemLabel,
    this.errorMessage,
  });

  const SyncProgress.idle() : this();

  /// Null means "indeterminate" — show a sweeping bar rather than a value.
  double? get fraction => total <= 0 ? null : (current / total).clamp(0, 1);

  bool get isActive =>
      stage != SyncStage.idle &&
      stage != SyncStage.completed &&
      stage != SyncStage.failed;
}
