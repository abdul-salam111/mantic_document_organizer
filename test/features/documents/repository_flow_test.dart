import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/database/app_database.dart';
import 'package:mantic_doc_org/core/notifications/expiry_notification_service.dart';
import 'package:mantic_doc_org/core/notifications/notification_plugin.dart';
import 'package:mantic_doc_org/core/notifications/reminder_preference_controller.dart';
import 'package:mantic_doc_org/core/notifications/sync_reminder_service.dart';
import 'package:mantic_doc_org/features/categories/data/datasources/category_local_datasource.dart';
import 'package:mantic_doc_org/features/categories/data/repository_impl/category_repository_impl.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/data/datasources/document_local_datasource.dart';
import 'package:mantic_doc_org/features/documents/data/repository_impl/document_repository_impl.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/favorites/data/repository_impl/favorites_repository_impl.dart';
import 'package:mantic_doc_org/features/favorites/domain/usecases/favorites_usecase.dart';

DocumentItem document(String id, {DateTime? createdAt, DateTime? expiry}) =>
    DocumentItem(
      id: id,
      title: 'Document $id',
      category: 'Bank',
      categoryId: 'bank',
      iconKey: 'file',
      createdAt: createdAt ?? DateTime(2026),
      tags: ['bank'],
      filePaths: ['/saved/$id.jpg'],
      description: 'Summary',
      ocrText: 'Recognized text',
      isExpirable: expiry != null,
      expiryDate: expiry,
    );

class MemoryDocuments implements DocumentLocalDataSource {
  final rows = <String, DocumentItem>{};
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<List<DocumentItem>> fetchDocuments() async => rows.values
      .where((d) => !d.isTrashed)
      .toList()
      .sortedBy(DocumentSort.newest);
  @override
  Future<List<DocumentItem>> fetchTrashedDocuments() async =>
      rows.values.where((d) => d.isTrashed).toList();
  @override
  Future<void> upsertDocument(DocumentItem item) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('disk full');
    rows[item.id] = item;
  }

  @override
  Future<void> softDeleteDocument(String id, DateTime date) async {
    if (fail) throw StateError('disk full');
    rows[id] = rows[id]!.markDeleted(date);
  }

  @override
  Future<void> softDeleteDocuments(Iterable<String> ids, DateTime date) async {
    if (fail) throw StateError('disk full');
    for (final id in ids) {
      rows[id] = rows[id]!.markDeleted(date);
    }
  }

  @override
  Future<void> restoreDocument(String id) async {
    rows[id] = rows[id]!.restored();
  }

  @override
  Future<void> deleteDocument(String id) async {
    rows.remove(id);
  }

  @override
  Future<void> deleteDocuments(Iterable<String> ids) async {
    if (fail) throw StateError('disk full');
    ids.forEach(rows.remove);
  }

  @override
  Future<void> purgeExpiredTrash(Duration retention) async {
    final cutoff = DateTime.now().subtract(retention);
    rows.removeWhere(
      (_, d) => d.deletedAt != null && d.deletedAt!.isBefore(cutoff),
    );
  }

  // No real files in this in-memory fake, so the "hash" is just the path
  // itself -- callers only ever compare it for equality, never read it.
  @override
  Future<String?> hashAttachment(String path) async => path;
  @override
  Future<({String documentId, bool isTrashed})?> findAttachmentMatch(
    String contentHash, {
    String? excludeDocumentId,
  }) async {
    for (final document in rows.values) {
      if (document.id == excludeDocumentId) continue;
      if (document.filePaths.contains(contentHash)) {
        return (documentId: document.id, isTrashed: document.isTrashed);
      }
    }
    return null;
  }
}

class ReminderSpy extends ExpiryNotificationService {
  ReminderSpy()
    : super(AppNotificationPlugin(), ReminderPreferenceController());
  final scheduled = <String>[];
  final cancelled = <String>[];
  final snoozed = <(String, Duration)>[];
  @override
  Future<void> scheduleForDocument(DocumentItem document) async {
    scheduled.add(document.id);
  }

  @override
  Future<void> scheduleWeeklyDigest(List<DocumentItem> documents) async {}
  @override
  Future<void> cancelForDocument(String id) async {
    cancelled.add(id);
  }

  @override
  Future<void> snooze(DocumentItem document, Duration by) async {
    snoozed.add((document.id, by));
  }
}

class SyncReminderSpy extends SyncReminderService {
  SyncReminderSpy() : super(AppNotificationPlugin(), AppDatabase());
  int refreshCount = 0;
  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}

class MemoryCategories implements CategoryLocalDataSource {
  final rows = <String, CategoryItem>{};
  bool fail = false;
  @override
  Future<List<CategoryItem>> fetchCategories() async => rows.values.toList();
  @override
  Future<void> seedBuiltInCategoriesIfEmpty(List<CategoryItem> items) async {
    if (rows.isEmpty) {
      for (final item in items) {
        rows[item.id] = item;
      }
    }
  }

  @override
  Future<void> upsertCategory(CategoryItem item) async {
    if (fail) throw StateError('disk full');
    rows[item.id] = item;
  }

  @override
  Future<void> deleteCategory(String id) => deleteCategories([id]);
  @override
  Future<void> deleteCategories(Iterable<String> ids) async {
    if (fail) throw StateError('disk full');
    ids.forEach(rows.remove);
  }
}

void main() {
  late MemoryDocuments storage;
  late ReminderSpy reminders;
  late SyncReminderSpy syncReminder;
  late DocumentRepositoryImpl repository;
  late DocumentUseCases documents;
  late FavoritesUsecase favorites;
  setUp(() async {
    storage = MemoryDocuments();
    reminders = ReminderSpy();
    syncReminder = SyncReminderSpy();
    repository = DocumentRepositoryImpl(storage, reminders, syncReminder);
    documents = DocumentUseCases(repository);
    favorites = FavoritesUsecase(
      repository: FavoritesRepositoryImpl(repository),
    );
    await documents.init();
  });
  tearDown(() => repository.dispose());

  test(
    'publishes only after persistence, and failures leave cache unchanged',
    () async {
      var changes = 0;
      documents.addListener(() => changes++);
      storage.gate = Completer<void>();
      final pending = documents.addDocument(document('a'));
      await Future<void>.delayed(Duration.zero);
      expect(documents.documents, isEmpty);
      expect(changes, 0);
      storage.gate!.complete();
      await pending;
      expect(changes, 1);
      storage.fail = true;
      await expectLater(documents.addDocument(document('b')), throwsStateError);
      expect(documents.documents.map((d) => d.id), ['a']);
      expect(changes, 1);
      storage.fail = false;
      await documents.addDocument(document('c'));
      expect(documents.documents.map((d) => d.id), ['c', 'a']);
    },
  );

  test(
    'favorite toggles use current state and preserve a newer rename',
    () async {
      final original = document('a');
      await documents.addDocument(original);
      await documents.updateDocument(original.copyWith(title: 'Renamed'));
      await favorites.toggleFavorite(original);
      expect(favorites.favorites.single.title, 'Renamed');
      await Future.wait([
        favorites.toggleFavorite(original),
        favorites.toggleFavorite(original),
      ]);
      expect(favorites.favorites, hasLength(1));
      expect(storage.rows['a']!.title, 'Renamed');
      expect(storage.rows['a']!.isFavorite, isTrue);
    },
  );

  test(
    'trash removes favorites; restore preserves fields and creation order',
    () async {
      final older = document('old', createdAt: DateTime(2025));
      await documents.addDocument(older);
      await documents.addDocument(document('new'));
      await favorites.toggleFavorite(older);
      await documents.trashDocument('old');
      expect(favorites.favorites, isEmpty);
      expect(documents.trashedDocuments.single.isTrashed, isTrue);
      expect(reminders.cancelled, contains('old'));
      await documents.restoreDocument('old');
      expect(documents.documents.map((d) => d.id), ['new', 'old']);
      final restored = favorites.favorites.single;
      expect(restored.tags, older.tags);
      expect(restored.filePaths, older.filePaths);
      expect(restored.ocrText, older.ocrText);
      expect(restored.description, older.description);
      expect(restored.deletedAt, isNull);
      expect(reminders.scheduled.last, 'old');
    },
  );

  test(
    'bulk trash moves every selected document and cancels their reminders',
    () async {
      await documents.addDocument(document('a'));
      await documents.addDocument(document('b'));
      await documents.addDocument(document('c'));
      await documents.trashDocuments(['a', 'c']);
      expect(documents.documents.map((d) => d.id), ['b']);
      expect(documents.trashedDocuments.map((d) => d.id).toSet(), {'a', 'c'});
      expect(reminders.cancelled, containsAll(['a', 'c']));
      expect(reminders.cancelled, isNot(contains('b')));
    },
  );

  test(
    'rescheduling expiry reminders reschedules every active document',
    () async {
      await documents.addDocument(document('a'));
      await documents.addDocument(document('b'));
      await documents.trashDocument('b');
      reminders.scheduled.clear();
      await documents.rescheduleExpiryReminders();
      expect(reminders.scheduled, ['a']);
    },
  );

  test(
    'snoozing an active document forwards to the notification service',
    () async {
      await documents.addDocument(document('a'));
      await documents.snoozeExpiryReminder('a', const Duration(days: 3));
      expect(reminders.snoozed, [('a', const Duration(days: 3))]);
    },
  );

  test(
    'adding, updating, and restoring a document each reconcile the sync reminder',
    () async {
      syncReminder.refreshCount = 0;
      await documents.addDocument(document('a'));
      expect(syncReminder.refreshCount, 1);
      await documents.updateDocument(storage.rows['a']!.copyWith(title: 'B'));
      expect(syncReminder.refreshCount, 2);
      await documents.trashDocument('a');
      await documents.restoreDocument('a');
      expect(syncReminder.refreshCount, 3);
    },
  );

  test('snoozing an unknown document id is a no-op', () async {
    await documents.addDocument(document('a'));
    await documents.snoozeExpiryReminder('missing', const Duration(days: 3));
    expect(reminders.snoozed, isEmpty);
  });

  test(
    'finds the document that already has an identical attachment, excluding '
    'the one specified and ignoring an unmatched path',
    () async {
      await documents.addDocument(document('a'));
      final match = await documents.findDuplicateOf('/saved/a.jpg');
      expect(match?.id, 'a');
      expect(
        await documents.findDuplicateOf(
          '/saved/a.jpg',
          excludeDocumentId: 'a',
        ),
        isNull,
      );
      expect(await documents.findDuplicateOf('/saved/nothing.jpg'), isNull);
    },
  );

  test(
    'a duplicate match still in trash is reported as trashed, never '
    'restored implicitly',
    () async {
      await documents.addDocument(document('a'));
      await documents.trashDocument('a');
      final match = await documents.findDuplicateOf('/saved/a.jpg');
      expect(match?.id, 'a');
      expect(match?.isTrashed, isTrue);
      expect(documents.documents, isEmpty);
    },
  );

  test('failed bulk trash retains recoverable state', () async {
    await documents.addDocument(document('a'));
    await documents.addDocument(document('b'));
    storage.fail = true;
    await expectLater(documents.trashDocuments(['a', 'b']), throwsStateError);
    expect(documents.documents, hasLength(2));
    expect(documents.trashedDocuments, isEmpty);
  });

  test('failed trash/empty trash retains recoverable state', () async {
    await documents.addDocument(document('a'));
    storage.fail = true;
    await expectLater(documents.trashDocument('a'), throwsStateError);
    expect(documents.documents, hasLength(1));
    expect(documents.trashedDocuments, isEmpty);
    storage.fail = false;
    await documents.trashDocument('a');
    storage.fail = true;
    await expectLater(documents.emptyTrash(), throwsStateError);
    expect(documents.trashedDocuments, hasLength(1));
    storage.fail = false;
    await documents.emptyTrash();
    expect(documents.trashedDocuments, isEmpty);
    expect(storage.rows, isEmpty);
  });

  test('permanent deletion cannot remove an active document', () async {
    await documents.addDocument(document('a'));
    await documents.permanentlyDeleteDocument('a');
    expect(storage.rows.keys, ['a']);
  });

  test('hydration purges expired trash and keeps recent trash', () async {
    storage.rows['expired'] = document(
      'expired',
    ).markDeleted(DateTime.now().subtract(const Duration(days: 31)));
    storage.rows['recent'] = document('recent').markDeleted(DateTime.now());
    await documents.init();
    expect(documents.trashedDocuments.map((d) => d.id), ['recent']);
    expect(storage.rows.containsKey('expired'), isFalse);
  });

  test(
    'expiry rule excludes expired and boundary dates, sorts soonest first',
    () async {
      final now = DateTime(2026, 9, 1);
      for (final days in [-1, 0, 1, 10, 30, 31]) {
        await documents.addDocument(
          document('$days', expiry: now.add(Duration(days: days))),
        );
      }
      expect(documents.expiringSoon(at: now).map((d) => d.id), ['1', '10']);
    },
  );

  test('entities snapshot mutable form lists', () {
    final tags = ['first'];
    final item = DocumentItem(
      id: 'a',
      title: 'A',
      category: 'Bank',
      categoryId: 'bank',
      iconKey: 'file',
      createdAt: DateTime(2026),
      tags: tags,
    );
    tags.add('second');
    expect(item.tags, ['first']);
    expect(() => item.tags.add('third'), throwsUnsupportedError);
  });

  test('category failures preserve data and later writes recover', () async {
    final data = MemoryCategories();
    final repo = CategoryRepositoryImpl(data);
    addTearDown(repo.dispose);
    final categories = CategoryUseCases(repo);
    await categories.init();
    final original = categories.categories.first;
    data.fail = true;
    await expectLater(categories.removeCategory(original.id), throwsStateError);
    expect(categories.byId(original.id), same(original));
    data.fail = false;
    final updated = CategoryItem(
      id: original.id,
      name: 'Renamed',
      iconKey: original.iconKey,
      colorValue: 0xff112233,
    );
    await categories.updateCategory(original.id, updated);
    expect(categories.exists(' RENAMED '), isTrue);
    expect(categories.exists('Renamed', excludingId: original.id), isFalse);
    expect(data.rows[original.id]!.colorValue, 0xff112233);
  });
}
