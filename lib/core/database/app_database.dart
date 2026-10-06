import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _db;

  /// Active local documents that still have an operation in the durable
  /// outbox. This is the source of truth for offline/sync indicators.
  final ValueNotifier<Set<String>> pendingDocumentIds = ValueNotifier(
    const <String>{},
  );

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
      version: 6,
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
        await _createSyncOutbox(db);
        await _createSyncState(db);
        await _createUploadedAttachments(db);
        await _createCategorySyncState(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE documents ADD COLUMN deleted_at INTEGER',
          );
        }
        if (oldVersion < 3) {
          await _createSyncOutbox(db);
        }
        if (oldVersion < 4) {
          await _createSyncState(db);
        }
        if (oldVersion < 5) {
          await _createUploadedAttachments(db);
        }
        if (oldVersion < 6) {
          await _createCategorySyncState(db);
        }
      },
    );
    await _refreshPendingDocumentIds();
  }

  /// Durable, local-first queue.  A mutation enters this table in the same
  /// transaction as the local database write; network availability never
  /// changes whether the user can save a document.
  Future<void> _createSyncOutbox(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS sync_outbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      attempt_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      UNIQUE(entity_type, entity_id)
    )
  ''');

  Future<void> _createSyncState(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS sync_document_state (
      local_document_id TEXT PRIMARY KEY,
      remote_document_id TEXT NOT NULL,
      remote_revision INTEGER NOT NULL
    )
  ''');

  Future<void> _createUploadedAttachments(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS sync_uploaded_attachments (
      local_document_id TEXT NOT NULL,
      local_path TEXT NOT NULL,
      remote_attachment_id TEXT NOT NULL,
      PRIMARY KEY(local_document_id, local_path)
    )
  ''');

  Future<void> _createCategorySyncState(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS sync_category_state (
      local_category_id TEXT PRIMARY KEY,
      remote_category_id TEXT NOT NULL UNIQUE
    )
  ''');

  Future<void> _enqueueDocumentMutation(
    DatabaseExecutor db,
    DocumentItem document,
    String operation,
  ) => db.insert('sync_outbox', {
    'entity_type': 'document',
    'entity_id': document.id,
    'operation': operation,
    'payload': _documentToSyncPayload(document),
    'created_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  String _documentToSyncPayload(DocumentItem document) => jsonEncode({
    'title': document.title,
    'description': document.description,
    'ocr_text': document.ocrText,
    'tags': document.tags,
    'category_id': document.categoryId,
    'is_expirable': document.isExpirable,
    'expiry_date': document.expiryDate?.toIso8601String(),
    'file_paths': document.filePaths,
  });

  Future<List<Map<String, Object?>>> pendingSyncOperations() =>
      _requireDb.query('sync_outbox', orderBy: 'id ASC');

  /// Backfills documents that predate backup connection into the outbox —
  /// needed when a person connects Drive after already using the offline
  /// app for a while. Only documents with no `sync_document_state` row are
  /// queued: a document already known to the server is kept in sync by its
  /// own edit/delete calls (`upsertDocument`/`softDeleteDocument`), not by
  /// being wholesale re-pushed here every time this runs. Re-queuing an
  /// already-synced document is how re-uploads/duplicate attachments used
  /// to happen on every repeat sync.
  Future<void> queueExistingDocumentsForSync() async {
    final documents = await fetchDocuments();
    await _requireDb.transaction((txn) async {
      for (final document in documents) {
        final synced = await txn.query(
          'sync_document_state',
          columns: ['local_document_id'],
          where: 'local_document_id = ?',
          whereArgs: [document.id],
        );
        if (synced.isNotEmpty) continue;
        await _enqueueDocumentMutation(txn, document, 'upsert');
      }
    });
    await _refreshPendingDocumentIds();
  }

  Future<void> completeSyncOperation(int id) async {
    await _requireDb.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
    await _refreshPendingDocumentIds();
  }

  Future<void> recordSyncFailure(int id) => _requireDb.rawUpdate(
    'UPDATE sync_outbox SET attempt_count = attempt_count + 1 WHERE id = ?',
    [id],
  );

  Future<Map<String, Object?>?> documentSyncState(String localId) async {
    final rows = await _requireDb.query(
      'sync_document_state',
      where: 'local_document_id = ?',
      whereArgs: [localId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String?> localDocumentIdForRemoteId(String remoteId) async {
    final rows = await _requireDb.query(
      'sync_document_state',
      columns: ['local_document_id'],
      where: 'remote_document_id = ?',
      whereArgs: [remoteId],
    );
    return rows.isEmpty ? null : rows.first['local_document_id'] as String;
  }

  Future<String?> remoteCategoryIdForLocalId(String localId) async {
    final rows = await _requireDb.query(
      'sync_category_state',
      columns: ['remote_category_id'],
      where: 'local_category_id = ?',
      whereArgs: [localId],
    );
    return rows.isEmpty ? null : rows.first['remote_category_id'] as String;
  }

  Future<String?> localCategoryIdForRemoteId(String remoteId) async {
    final rows = await _requireDb.query(
      'sync_category_state',
      columns: ['local_category_id'],
      where: 'remote_category_id = ?',
      whereArgs: [remoteId],
    );
    return rows.isEmpty ? null : rows.first['local_category_id'] as String;
  }

  Future<void> saveCategorySyncState({
    required String localId,
    required String remoteId,
  }) => _requireDb.insert('sync_category_state', {
    'local_category_id': localId,
    'remote_category_id': remoteId,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<DocumentItem?> documentById(String id) async {
    final rows = await _requireDb.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final attachments = await _requireDb.query(
      'document_attachments',
      where: 'document_id = ?',
      whereArgs: [id],
      orderBy: 'sort_order ASC',
    );
    return _documentFromRow(
      rows.first,
      tags: const [],
      filePaths: [for (final row in attachments) row['path'] as String],
    );
  }

  Future<void> saveDocumentSyncState({
    required String localId,
    required String remoteId,
    required int revision,
  }) => _requireDb.insert('sync_document_state', {
    'local_document_id': localId,
    'remote_document_id': remoteId,
    'remote_revision': revision,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// The server copy was removed outside the app while this active local
  /// document still exists. Forget its obsolete remote identity and queue a
  /// full create/upload so the local-first copy is never lost.
  Future<void> requeueDocumentForRemoteRestore(DocumentItem document) async {
    await _requireDb.transaction((txn) async {
      await _clearDocumentRemoteState(txn, document.id);
      await _enqueueDocumentMutation(txn, document, 'upsert');
    });
    await _refreshPendingDocumentIds();
  }

  /// Removes mappings to a remote document that no longer exists. Used for
  /// an idempotent delete as well as restoring an active local document.
  Future<void> clearDocumentRemoteState(String documentId) => _requireDb
      .transaction((txn) => _clearDocumentRemoteState(txn, documentId));

  Future<void> _clearDocumentRemoteState(
    DatabaseExecutor db,
    String documentId,
  ) async {
    await db.delete(
      'sync_document_state',
      where: 'local_document_id = ?',
      whereArgs: [documentId],
    );
    await db.delete(
      'sync_uploaded_attachments',
      where: 'local_document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<bool> isAttachmentUploaded(String documentId, String path) async {
    final rows = await _requireDb.query(
      'sync_uploaded_attachments',
      where: 'local_document_id = ? AND local_path = ?',
      whereArgs: [documentId, path],
    );
    return rows.isNotEmpty;
  }

  Future<void> markAttachmentUploaded({
    required String documentId,
    required String path,
    required String remoteAttachmentId,
  }) => _requireDb.insert('sync_uploaded_attachments', {
    'local_document_id': documentId,
    'local_path': path,
    'remote_attachment_id': remoteAttachmentId,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// The local path this device originally pushed as [remoteAttachmentId],
  /// if any — lets a failed download (the server's copy is gone) fall back
  /// to re-uploading the file this device still has, instead of just
  /// giving up on it.
  Future<String?> localPathForRemoteAttachment(
    String documentId,
    String remoteAttachmentId,
  ) async {
    final rows = await _requireDb.query(
      'sync_uploaded_attachments',
      where: 'local_document_id = ? AND remote_attachment_id = ?',
      whereArgs: [documentId, remoteAttachmentId],
    );
    return rows.isEmpty ? null : rows.first['local_path'] as String;
  }

  Future<void> clearAttachmentUploaded(
    String documentId,
    String remoteAttachmentId,
  ) => _requireDb.delete(
    'sync_uploaded_attachments',
    where: 'local_document_id = ? AND remote_attachment_id = ?',
    whereArgs: [documentId, remoteAttachmentId],
  );

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<List<CategoryItem>> fetchCategories() async {
    final rows = await _requireDb.query('categories');
    return [for (final row in rows) _categoryFromRow(row)];
  }

  Future<void> seedBuiltInCategoriesIfEmpty(List<CategoryItem> builtIns) async {
    final countResult = Sqflite.firstIntValue(
      await _requireDb.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    final batch = _requireDb.batch();
    if ((countResult ?? 0) == 0) {
      for (final category in builtIns) {
        batch.insert('categories', _categoryToRow(category));
      }
    } else {
      // Earlier versions derived built-in colors in the UI and persisted
      // null. Backfill only missing values so a user-selected color remains.
      for (final category in builtIns) {
        batch.update(
          'categories',
          {'color': category.colorValue},
          where: 'id = ? AND color IS NULL',
          whereArgs: [category.id],
        );
      }
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
    'color': category.colorValue,
  };

  CategoryItem _categoryFromRow(Map<String, Object?> row) => CategoryItem(
    id: row['id'] as String,
    name: row['name'] as String,
    iconKey: row['icon_key'] as String,
    colorValue: row['color'] as int?,
  );

  // ---------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------
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

  Future<List<DocumentItem>> fetchDocuments() =>
      _queryDocuments('deleted_at IS NULL', 'created_at DESC');
  Future<List<DocumentItem>> fetchTrashedDocuments() =>
      _queryDocuments('deleted_at IS NOT NULL', 'deleted_at DESC');
  Future<void> upsertDocument(DocumentItem document) async {
    await _requireDb.transaction((txn) async {
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
      await _enqueueDocumentMutation(txn, document, 'upsert');
    });
    await _refreshPendingDocumentIds();
  }

  /// Applies a server document without creating another outbound mutation.
  /// Used during restore on a newly installed device.
  Future<void> applyRemoteDocument(DocumentItem document) =>
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
        await txn.delete(
          'document_attachments',
          where: 'document_id = ?',
          whereArgs: [document.id],
        );
        for (final tag in document.tags) {
          await txn.insert('document_tags', {
            'document_id': document.id,
            'tag': tag,
          });
        }
        for (var i = 0; i < document.filePaths.length; i++) {
          await txn.insert('document_attachments', {
            'document_id': document.id,
            'path': document.filePaths[i],
            'sort_order': i,
          });
        }
      });
  Future<void> deleteDocument(String id) =>
      _requireDb.delete('documents', where: 'id = ?', whereArgs: [id]);
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

  Future<void> softDeleteDocument(String id, DateTime deletedAt) async {
    await _requireDb.transaction((txn) async {
      await _softDeleteDocumentInTxn(txn, id, deletedAt);
    });
    await _refreshPendingDocumentIds();
  }

  /// Bulk counterpart to [softDeleteDocument] — one transaction for every
  /// id instead of one per id, mirroring [deleteDocuments]'s own batching.
  Future<void> softDeleteDocuments(
    Iterable<String> ids,
    DateTime deletedAt,
  ) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await _requireDb.transaction((txn) async {
      for (final id in idList) {
        await _softDeleteDocumentInTxn(txn, id, deletedAt);
      }
    });
    await _refreshPendingDocumentIds();
  }

  Future<void> _softDeleteDocumentInTxn(
    Transaction txn,
    String id,
    DateTime deletedAt,
  ) async {
    await txn.update(
      'documents',
      {'deleted_at': deletedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
    final rows = await txn.query('documents', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await _enqueueDocumentMutation(
        txn,
        _documentFromRow(rows.first, tags: const [], filePaths: const []),
        'delete',
      );
    }
  }

  Future<void> restoreDocument(String id) async {
    await _requireDb.transaction((txn) async {
      await txn.update(
        'documents',
        {'deleted_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await txn.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isNotEmpty) {
        // A restore must cancel a previously queued delete. Otherwise an
        // offline trash action can delete the server copy after the user has
        // already restored the document locally.
        await _enqueueDocumentMutation(
          txn,
          _documentFromRow(rows.first, tags: const [], filePaths: const []),
          'upsert',
        );
      }
    });
    await _refreshPendingDocumentIds();
  }

  Future<void> purgeExpiredTrash(Duration retention) async {
    final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    await _requireDb.delete(
      'documents',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  Future<void> _refreshPendingDocumentIds() async {
    final rows = await _requireDb.query(
      'sync_outbox',
      columns: ['entity_id'],
      where: 'entity_type = ?',
      whereArgs: ['document'],
    );
    pendingDocumentIds.value = Set.unmodifiable(
      rows.map((row) => row['entity_id'] as String).toSet(),
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
