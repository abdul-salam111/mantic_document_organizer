import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/notifications/expiry_notification_service.dart';
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
}

class ReminderSpy extends ExpiryNotificationService {
  final scheduled = <String>[];
  final cancelled = <String>[];
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
  late DocumentRepositoryImpl repository;
  late DocumentUseCases documents;
  late FavoritesUsecase favorites;
  setUp(() async {
    storage = MemoryDocuments();
    reminders = ReminderSpy();
    repository = DocumentRepositoryImpl(storage, reminders);
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
