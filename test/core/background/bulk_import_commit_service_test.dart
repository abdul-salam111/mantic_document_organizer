import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/background/bulk_import_commit_service.dart';
import 'package:mantic_doc_org/core/notifications/bulk_import_commit_notifications.dart';
import 'package:mantic_doc_org/core/notifications/notification_plugin.dart';
import '../../features/bulk_import/bulk_import_fakes.dart';

/// Records what would have been shown instead of actually calling into
/// `flutter_local_notifications` -- its platform channel isn't mocked in
/// this test harness (same reason `AutoImportService`'s own notification
/// calls aren't exercised directly either), so every real
/// [BulkImportCommitNotifications] method is overridden to a no-op here.
class _RecordingNotifications extends BulkImportCommitNotifications {
  _RecordingNotifications() : super(AppNotificationPlugin());

  final importingCalls = <(int completed, int total)>[];
  final resultCalls = <(int imported, int failedCount)>[];

  @override
  Future<void> showImporting({
    required int completed,
    required int total,
  }) async {
    importingCalls.add((completed, total));
  }

  @override
  Future<void> showResult({
    required int imported,
    required int failedCount,
  }) async {
    resultCalls.add((imported, failedCount));
  }

  @override
  void dispose() {}
}

void main() {
  late ImportFixture f;
  late _RecordingNotifications notifications;
  late BulkImportCommitService service;

  setUp(() {
    f = ImportFixture();
    notifications = _RecordingNotifications();
    service = BulkImportCommitService(notifications: notifications);
  });

  test(
    'a fully successful commit reports the result and disposes the viewmodel',
    () async {
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      service.runInBackground(f.vm);
      await pumpEventQueue();
      expect(notifications.resultCalls, [(2, 0)]);
      expect(f.documents.documents.length, 2);
      // Disposed -> cancel() -> discard(), same as leaving the review
      // screen without importing -- the service is the sole owner now.
      expect(f.imports.discarded, 1);
    },
  );

  test(
    'a partial failure keeps the viewmodel alive for review instead of disposing it',
    () async {
      f.seedFound([candidate('a'), candidate('b')]);
      f.imports.copyFailures.add('b');
      await f.vm.discover();
      service.runInBackground(f.vm);
      await pumpEventQueue();
      expect(notifications.resultCalls, [(1, 1)]);
      expect(f.vm.candidates.map((c) => c.id), ['b']);
      expect(f.imports.discarded, 0);
    },
  );

  test(
    'progress is forwarded to the notification as the commit proceeds',
    () async {
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      service.runInBackground(f.vm);
      await pumpEventQueue();
      expect(notifications.importingCalls, isNotEmpty);
      expect(notifications.importingCalls.last, (2, 2));
    },
  );
}
