import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/background/auto_import_service.dart';
import 'package:mantic_doc_org/core/local_storage/local_storage_exports.dart';
import 'package:mantic_doc_org/core/notifications/auto_import_notifications.dart';
import 'package:mantic_doc_org/core/notifications/notification_plugin.dart';
import '../../features/bulk_import/bulk_import_fakes.dart';

/// Overrides the real notification-sending methods (which would otherwise
/// hit the real `flutter_local_notifications` platform channel) while
/// keeping everything else -- including the tap-dispatch wiring
/// AutoImportService's constructor relies on -- exactly as production has
/// it. Same pattern as `ReminderSpy extends ExpiryNotificationService` in
/// repository_flow_test.dart.
class FakeAutoImportNotifications extends AutoImportNotifications {
  FakeAutoImportNotifications() : super(AppNotificationPlugin());

  final scanningCalls = <int>[];
  final foundCalls = <int>[];
  int dismissQuietCalls = 0;

  @override
  Future<void> showScanning({
    required int examined,
    required int totalEstimate,
  }) async {
    scanningCalls.add(examined);
  }

  @override
  Future<void> showFound(int count) async {
    foundCalls.add(count);
  }

  @override
  Future<void> dismissQuiet() async {
    dismissQuietCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImportFixture f;
  late FakeAutoImportNotifications notifications;
  late AutoImportService service;

  setUp(() {
    // In-memory fake for the `storage` singleton (flutter_secure_storage)
    // AutoImportService persists its "already ran" flag through.
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    f = ImportFixture();
    notifications = FakeAutoImportNotifications();
    service = AutoImportService(
      createViewModel: () => f.vm,
      notifications: notifications,
    );
  });

  // AutoImportService itself disposes the scan's viewmodel when nothing is
  // found (see _runScan), but leaves it alive -- handed off to
  // BulkImportReviewView in production -- when something is pending
  // review. ChangeNotifier.dispose() asserts against being called twice,
  // so each test cleans up only when it knows the vm wasn't already
  // disposed by the service (i.e. a "found" notification fired).
  Future<void> disposeIfLeftPending() async {
    if (notifications.foundCalls.isEmpty) return;
    await f.vm.cancel();
    f.vm.dispose();
  }

  test(
    'a successful scan shows a tappable "found" notification and records the flag',
    () async {
      f.seedFound([candidate('a'), candidate('b')]);
      await service.onPermissionGranted();
      expect(notifications.foundCalls, [2]);
      expect(notifications.dismissQuietCalls, 0);
      expect(
        await storage.readValues(StorageKeys.hasRunInitialAutoImport),
        'true',
      );
      await disposeIfLeftPending();
    },
  );

  test(
    'tapping the found notification routes through the service without throwing',
    () async {
      f.seedFound([candidate('a')]);
      await service.onPermissionGranted();
      // AppNavigator.pushNamed no-ops when there's no live navigator (as
      // here, outside a widget tree) -- this only proves the service's own
      // tap-dispatch wiring runs end to end without error.
      expect(() => notifications.onReviewTapped?.call(), returnsNormally);
      await disposeIfLeftPending();
    },
  );

  test(
    'finding nothing dismisses quietly instead of showing a notification',
    () async {
      await service.onPermissionGranted();
      expect(notifications.foundCalls, isEmpty);
      expect(notifications.dismissQuietCalls, 1);
      await disposeIfLeftPending();
    },
  );

  test('runs at most once per install', () async {
    f.seedFound([candidate('a')]);
    await service.onPermissionGranted();
    expect(notifications.foundCalls, [1]);
    f.seedFound([candidate('b')]);
    await service.onPermissionGranted();
    expect(notifications.foundCalls, [1]); // unchanged -- no second scan.
    await disposeIfLeftPending();
  });

  test(
    'maybeRunInitialScan never prompts, only checks passively',
    () async {
      f.discovery.passivelyGranted = true;
      f.seedFound([candidate('a')]);
      await service.maybeRunInitialScan();
      expect(f.discovery.requestPermissionCalls, 0);
      // Once for the upfront "is there anything worth attempting at all"
      // gate, once more inside the actual scan's own per-source check.
      expect(f.discovery.hasPermissionCalls, 2);
      expect(notifications.foundCalls, [1]);
      await disposeIfLeftPending();
    },
  );

  test(
    'maybeRunInitialScan skips entirely, without spending the one-shot flag, '
    'when nothing is granted yet (pre-consent fresh install)',
    () async {
      f.discovery.passivelyGranted = false;
      f.seedFound([candidate('a')]);
      await service.maybeRunInitialScan();
      expect(f.discovery.findCandidatesCalls, 0);
      expect(notifications.foundCalls, isEmpty);
      // Bails out before _runScan -- never shows, never dismisses.
      expect(notifications.dismissQuietCalls, 0);
      // The one-shot flag must still be unspent -- proving the real,
      // permission-prompting path (onPermissionGranted, covered by
      // separate tests above) still gets its chance later.
      expect(
        await storage.readValues(StorageKeys.hasRunInitialAutoImport),
        isNot('true'),
      );
    },
  );

  test('onPermissionGranted allows a real permission prompt', () async {
    f.seedFound([candidate('a')]);
    await service.onPermissionGranted();
    expect(f.discovery.requestPermissionCalls, 1);
    await disposeIfLeftPending();
  });

  test(
    'the automatic scan (onPermissionGranted) leaves a never-scanned '
    "source's `since` null, so it falls back to the discovery datasource's "
    'own ~12-month window',
    () async {
      f.seedFound([candidate('a')]);
      await service.onPermissionGranted();
      expect(f.discovery.lastSince, isNull);
      await disposeIfLeftPending();
    },
  );

  test(
    'runManualScan (Profile -> Find more documents) prompts and is repeatable',
    () async {
      f.seedFound([candidate('a')]);
      await service.runManualScan();
      expect(f.discovery.requestPermissionCalls, 1);
      expect(notifications.foundCalls, [1]);
      // Never gated by the one-shot flag -- running it again is allowed
      // even though the flag was never set by this entry point.
      expect(
        await storage.readValues(StorageKeys.hasRunInitialAutoImport),
        isNot('true'),
      );
      await disposeIfLeftPending();
    },
  );

  test(
    'runManualScan overrides a never-scanned source with an epoch `since`, '
    'so it covers the whole history instead of only the last ~12 months',
    () async {
      f.seedFound([candidate('a')]);
      await service.runManualScan();
      expect(f.discovery.lastSince, DateTime.fromMillisecondsSinceEpoch(0));
      await disposeIfLeftPending();
    },
  );

  test(
    'runManualScan still works after the one-shot flag is already spent',
    () async {
      await storage.setValues(StorageKeys.hasRunInitialAutoImport, 'true');
      f.seedFound([candidate('a')]);
      await service.runManualScan();
      expect(notifications.foundCalls, [1]);
      await disposeIfLeftPending();
    },
  );
}
