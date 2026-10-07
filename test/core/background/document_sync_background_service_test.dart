import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/background/document_sync_background_service.dart';
import 'package:mantic_doc_org/core/database/database_exports.dart';
import 'package:mantic_doc_org/core/notifications/document_sync_notifications.dart';
import 'package:mantic_doc_org/core/notifications/notification_plugin.dart';
import 'package:mantic_doc_org/features/backup/data/services/document_sync_service.dart';
import 'package:mantic_doc_org/features/backup/domain/entities/sync_progress.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import '../../features/bulk_import/bulk_import_fakes.dart';

/// Overrides only `sync()` -- everything it would otherwise do (real HTTP
/// calls via Dio) is replaced with scripted progress updates -- same
/// pattern as `ReminderSpy extends ExpiryNotificationService`.
class FakeDocumentSyncService extends DocumentSyncService {
  FakeDocumentSyncService() : super(AppDatabase(), Dio());

  int syncCalls = 0;
  String? lastToken;
  String? lastSpaceId;
  Object? error;
  Completer<void>? gate;

  @override
  Future<void> sync({required String token, required String spaceId}) async {
    syncCalls++;
    lastToken = token;
    lastSpaceId = spaceId;
    progress.value = const SyncProgress(
      stage: SyncStage.documents,
      direction: SyncDirection.upload,
      current: 1,
      total: 1,
      itemLabel: 'Doc A',
    );
    if (gate != null) await gate!.future;
    if (error != null) {
      final failure = SyncProgress(
        stage: SyncStage.failed,
        errorMessage: error.toString(),
      );
      progress.value = failure;
      throw error!;
    }
    progress.value = const SyncProgress(stage: SyncStage.completed);
  }
}

class FakeAppDatabase extends AppDatabase {
  int queueCalls = 0;

  @override
  Future<void> queueExistingDocumentsForSync() async {
    queueCalls++;
  }
}

class FakeDocumentSyncNotifications extends DocumentSyncNotifications {
  FakeDocumentSyncNotifications() : super(AppNotificationPlugin());

  final syncingCalls = <int>[];
  int completedCalls = 0;
  final failedMessages = <String>[];

  @override
  Future<void> showSyncing({
    required int current,
    required int total,
    required String label,
  }) async {
    syncingCalls.add(current);
  }

  @override
  Future<void> showCompleted() async {
    completedCalls++;
  }

  @override
  Future<void> showFailed(String message) async {
    failedMessages.add(message);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDocumentSyncService syncService;
  late FakeAppDatabase database;
  late FakeDocumentSyncNotifications notifications;
  late DocumentSyncBackgroundService service;

  setUp(() {
    syncService = FakeDocumentSyncService();
    database = FakeAppDatabase();
    notifications = FakeDocumentSyncNotifications();
    service = DocumentSyncBackgroundService(
      syncService: syncService,
      database: database,
      documents: DocumentUseCases(FakeDocuments()),
      notifications: notifications,
    );
  });

  test('a successful backup shows a completed notification', () async {
    await service.runBackup(token: 't', spaceId: 's');
    expect(syncService.syncCalls, 1);
    expect(syncService.lastToken, 't');
    expect(syncService.lastSpaceId, 's');
    expect(notifications.completedCalls, 1);
    expect(notifications.failedMessages, isEmpty);
    expect(notifications.syncingCalls, isNotEmpty);
  });

  test(
    'queueExistingDocuments is opt-in, matching "Back up now" vs "Retry"',
    () async {
      await service.runBackup(token: 't', spaceId: 's');
      expect(database.queueCalls, 0);
      await service.runBackup(
        token: 't',
        spaceId: 's',
        queueExistingDocuments: true,
      );
      expect(database.queueCalls, 1);
    },
  );

  test("a failure surfaces the sync service's own error message", () async {
    syncService.error = StateError('boom');
    await service.runBackup(token: 't', spaceId: 's');
    expect(notifications.completedCalls, 0);
    expect(notifications.failedMessages.single, contains('boom'));
  });

  test('reentrant calls are ignored while a sync is already running', () async {
    syncService.gate = Completer<void>();
    final first = service.runBackup(token: 't', spaceId: 's');
    await pumpEventQueue();
    final second = service.runBackup(token: 't', spaceId: 's');
    syncService.gate!.complete();
    await first;
    await second;
    expect(syncService.syncCalls, 1);
    expect(notifications.completedCalls, 1);
  });
}
