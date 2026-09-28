import 'package:flutter/material.dart' show Color;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/home/home_exports.dart' show CategoryItem, DocumentItem;

/// The on-device source of truth for [CategoryItem]/[DocumentItem] — hides
/// `sqflite` entirely behind plain Dart-facing methods, same shape as
/// [DioHelper]/[OcrService] hiding their own SDKs. [CategoryLocalStore]/
/// [DocumentLocalStore] (home_viewmodel.dart) are the only callers: they
/// keep their existing in-memory `List` + [ChangeNotifier] behavior for
/// every screen that already reads them synchronously, and use this class
/// only to hydrate that cache at startup and persist changes to it in the
/// background afterward.
class AppDatabase {
  Database? _db;

  Database get _requireDb {
    final db = _db;
    if (db == null) {
      throw StateError('AppDatabase.init() must be called before use.');
    }
    return db;
  }

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'mantic.db');
    _db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            color INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            category_id TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            is_expirable INTEGER NOT NULL DEFAULT 0,
            expiry_date INTEGER,
            description TEXT NOT NULL DEFAULT '',
            ocr_text TEXT NOT NULL DEFAULT '',
            deleted_at INTEGER
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_documents_category_id ON documents(category_id)',
        );
        await db.execute('''
          CREATE TABLE document_tags (
            document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
            tag TEXT NOT NULL,
            PRIMARY KEY (document_id, tag)
          )
        ''');
        await db.execute('''
          CREATE TABLE document_attachments (
            document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
            path TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            PRIMARY KEY (document_id, sort_order)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE documents ADD COLUMN deleted_at INTEGER',
          );
        }
      },
    );
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<List<CategoryItem>> fetchCategories() async {
    final rows = await _requireDb.query('categories');
    return [for (final row in rows) _categoryFromRow(row)];
  }

  /// Seeds [builtIns] only on a genuinely empty table — a fresh install, or
  /// a pre-existing install from before this migration. Never overwrites
  /// anything on a later launch, so a renamed/deleted built-in stays that
  /// way.
  Future<void> seedBuiltInCategoriesIfEmpty(List<CategoryItem> builtIns) async {
    final countResult = Sqflite.firstIntValue(
      await _requireDb.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if ((countResult ?? 0) > 0) return;
    final batch = _requireDb.batch();
    for (final category in builtIns) {
      batch.insert('categories', _categoryToRow(category));
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertCategory(CategoryItem category) => _requireDb.insert(
    'categories',
    _categoryToRow(category),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> deleteCategory(String id) =>
      _requireDb.delete('categories', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteCategories(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    final placeholders = List.filled(idList.length, '?').join(',');
    await _requireDb.delete(
      'categories',
      where: 'id IN ($placeholders)',
      whereArgs: idList,
    );
  }

  Map<String, Object?> _categoryToRow(CategoryItem category) => {
    'id': category.id,
    'name': category.name,
    'icon_key': category.iconKey,
    'color': category.color?.toARGB32(),
  };

  CategoryItem _categoryFromRow(Map<String, Object?> row) => CategoryItem(
    id: row['id'] as String,
    name: row['name'] as String,
    iconKey: row['icon_key'] as String,
    color: row['color'] == null ? null : Color(row['color'] as int),
  );

  // ---------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------

  /// Shared by [fetchDocuments]/[fetchTrashedDocuments] so the tag/
  /// attachment join-and-group logic isn't duplicated per fetch. Tags/
  /// attachments are each fetched in one query for the whole table
  /// (regardless of [where]) rather than per-document, so hydrating N
  /// documents costs 3 queries total, not `1 + 2N`.
  Future<List<DocumentItem>> _queryDocuments(
    String where,
    String orderBy,
  ) async {
    final documentRows = await _requireDb.query(
      'documents',
      where: where,
      orderBy: orderBy,
    );
    final tagRows = await _requireDb.query('document_tags');
    final attachmentRows = await _requireDb.query(
      'document_attachments',
      orderBy: 'sort_order ASC',
    );

    final tagsByDocument = <String, List<String>>{};
    for (final row in tagRows) {
      (tagsByDocument[row['document_id'] as String] ??= []).add(
        row['tag'] as String,
      );
    }
    final attachmentsByDocument = <String, List<String>>{};
    for (final row in attachmentRows) {
      (attachmentsByDocument[row['document_id'] as String] ??= []).add(
        row['path'] as String,
      );
    }

    return [
      for (final row in documentRows)
        _documentFromRow(
          row,
          tags: tagsByDocument[row['id'] as String] ?? const [],
          filePaths: attachmentsByDocument[row['id'] as String] ?? const [],
        ),
    ];
  }

  /// Newest first (matches [DocumentLocalStore.documents]' documented
  /// order) — active documents only.
  Future<List<DocumentItem>> fetchDocuments() =>
      _queryDocuments('deleted_at IS NULL', 'created_at DESC');

  /// Newest-deleted first (matches [DocumentLocalStore.trashedDocuments]).
  Future<List<DocumentItem>> fetchTrashedDocuments() =>
      _queryDocuments('deleted_at IS NOT NULL', 'deleted_at DESC');

  /// Insert-or-update, plus a full replace of this document's tags/
  /// attachments — simplest correct way to persist a list-valued field
  /// without diffing it, and cheap enough at this scale (a handful of tags/
  /// attachments per document).
  Future<void> upsertDocument(DocumentItem document) =>
      _requireDb.transaction((txn) async {
        await txn.insert(
          'documents',
          _documentToRow(document),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.delete(
          'document_tags',
          where: 'document_id = ?',
          whereArgs: [document.id],
        );
        for (final tag in document.tags) {
          await txn.insert('document_tags', {
            'document_id': document.id,
            'tag': tag,
          });
        }
        await txn.delete(
          'document_attachments',
          where: 'document_id = ?',
          whereArgs: [document.id],
        );
        for (var i = 0; i < document.filePaths.length; i++) {
          await txn.insert('document_attachments', {
            'document_id': document.id,
            'path': document.filePaths[i],
            'sort_order': i,
          });
        }
      });

  /// Also removes this document's tags/attachments — `ON DELETE CASCADE`
  /// (with `PRAGMA foreign_keys = ON`, set in [init]) handles that without
  /// needing explicit statements here.
  Future<void> deleteDocument(String id) =>
      _requireDb.delete('documents', where: 'id = ?', whereArgs: [id]);

  /// Bulk hard-delete — mirrors [deleteCategories]. Used by
  /// [DocumentLocalStore.emptyTrash].
  Future<void> deleteDocuments(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    final placeholders = List.filled(idList.length, '?').join(',');
    await _requireDb.delete(
      'documents',
      where: 'id IN ($placeholders)',
      whereArgs: idList,
    );
  }

  /// Soft delete — stamps `deleted_at` only, leaving every other column
  /// (including tags/attachments) intact so [restoreDocument] reproduces
  /// the document exactly.
  Future<void> softDeleteDocument(String id, DateTime deletedAt) =>
      _requireDb.update(
        'documents',
        {'deleted_at': deletedAt.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Undoes [softDeleteDocument].
  Future<void> restoreDocument(String id) => _requireDb.update(
    'documents',
    {'deleted_at': null},
    where: 'id = ?',
    whereArgs: [id],
  );

  /// Hard-deletes every trashed document past [retention] — called once at
  /// [DocumentLocalStore.init]. No scheduler needed: this app has no
  /// background-job infrastructure, and a once-per-launch check is
  /// sufficient for a local-only, single-user app.
  Future<void> purgeExpiredTrash(Duration retention) async {
    final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    await _requireDb.delete(
      'documents',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  Map<String, Object?> _documentToRow(DocumentItem document) => {
    'id': document.id,
    'title': document.title,
    'category': document.category,
    'category_id': document.categoryId,
    'icon_key': document.iconKey,
    'is_favorite': document.isFavorite ? 1 : 0,
    'created_at': document.createdAt.millisecondsSinceEpoch,
    'is_expirable': document.isExpirable ? 1 : 0,
    'expiry_date': document.expiryDate?.millisecondsSinceEpoch,
    'description': document.description,
    'ocr_text': document.ocrText,
    'deleted_at': document.deletedAt?.millisecondsSinceEpoch,
  };

  DocumentItem _documentFromRow(
    Map<String, Object?> row, {
    required List<String> tags,
    required List<String> filePaths,
  }) => DocumentItem(
    id: row['id'] as String,
    title: row['title'] as String,
    category: row['category'] as String,
    categoryId: row['category_id'] as String,
    iconKey: row['icon_key'] as String,
    isFavorite: (row['is_favorite'] as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    isExpirable: (row['is_expirable'] as int) == 1,
    expiryDate: row['expiry_date'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['expiry_date'] as int),
    description: row['description'] as String,
    ocrText: row['ocr_text'] as String,
    deletedAt: row['deleted_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int),
    tags: tags,
    filePaths: filePaths,
  );
}
