import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/background/bulk_import_seed_service.dart';
import 'package:mantic_doc_org/core/notifications/bulk_import_seed_notifications.dart';
import 'package:mantic_doc_org/core/notifications/notification_plugin.dart';
import '../../features/bulk_import/bulk_import_fakes.dart';

/// Records what would have been shown instead of actually calling into
/// `flutter_local_notifications` -- same reason as
/// `bulk_import_commit_service_test.dart`'s own recorder.
class _RecordingNotifications extends BulkImportSeedNotifications {
  _RecordingNotifications() : super(AppNotificationPlugin());

  final organizingCalls = <(int examined, int total)>[];
  int dismissQuietCalls = 0;

  @override
  Future<void> showOrganizing({
    required int examined,
    required int total,
  }) async {
    organizingCalls.add((examined, total));
  }

  @override
  Future<void> dismissQuiet() async {
    dismissQuietCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImportFixture f;
  late _RecordingNotifications notifications;
  late BulkImportSeedService service;

  setUp(() {
    f = ImportFixture();
    notifications = _RecordingNotifications();
    service = BulkImportSeedService(notifications: notifications);
  });

  test(
    'a successful seed dismisses the progress notification and leaves the '
    'viewmodel (with its grouped candidates) ready to open for review',
    () async {
      f.imports.picked = [candidate('a'), candidate('b')];
      service.runInBackground(f.vm, ['/shared/a.jpg', '/shared/b.jpg']);
      await pumpEventQueue();
      expect(notifications.dismissQuietCalls, 1);
      expect(f.vm.candidates.map((c) => c.id).toSet(), {'a', 'b'});
    },
  );

  test('a failed seed (offline) dismisses the progress notification and '
      'disposes the viewmodel instead of opening review', () async {
    f.connectivity.online = false;
    service.runInBackground(f.vm, ['/shared/a.jpg']);
    await pumpEventQueue();
    expect(notifications.dismissQuietCalls, 1);
  });

  test(
    'progress is forwarded to the notification as the seed proceeds',
    () async {
      f.imports.picked = [candidate('a'), candidate('b')];
      service.runInBackground(f.vm, ['/shared/a.jpg', '/shared/b.jpg']);
      await pumpEventQueue();
      expect(notifications.organizingCalls, isNotEmpty);
      expect(notifications.organizingCalls.first, (0, 2));
    },
  );
}
