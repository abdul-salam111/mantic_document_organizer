import 'package:mantic_doc_org/features/documents/domain/entities/document_policy.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../../../../core/notifications/expiry_notification_service.dart';

class DocumentRepositoryImpl extends ChangeNotifier
    implements IDocumentRepository {
  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'document reminders',
        ),
      );
    }
  }

  Future<void> _schedule(DocumentItem document) async {
    await _bestEffort(() => _notifications.scheduleForDocument(document));
    _refreshDigest();
  }

  Future<void> _cancel(String id) =>
      _bestEffort(() => _notifications.cancelForDocument(id));
  Future<void> _pending = Future.value();
  Future<void> _write(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  final DocumentLocalDataSource _db;
  final ExpiryNotificationService _notifications;

  DocumentRepositoryImpl(this._db, this._notifications);
  static const Duration trashRetentionPeriod =
      DocumentPolicy.trashRetentionPeriod;

  final List<DocumentItem> _documents = [];
  final List<DocumentItem> _trashedDocuments = [];
  @override
  List<DocumentItem> get documents => List.unmodifiable(_documents);
  @override
  List<DocumentItem> get trashedDocuments =>
      List.unmodifiable(_trashedDocuments);
  @override
  Future<void> init() async {
    await _db.purgeExpiredTrash(trashRetentionPeriod);
    _documents
      ..clear()
      ..addAll(await _db.fetchDocuments());
    _trashedDocuments
      ..clear()
      ..addAll(await _db.fetchTrashedDocuments());
    notifyListeners();
    // Reconciles every active document's expiry reminders against
    // whatever's actually scheduled on the device — covers both a document
    // saved before this feature existed (nothing scheduled for it yet) and
    // a scheduled reminder surviving from a previous install/build.
    for (final document in _documents) {
      await _bestEffort(() => _notifications.scheduleForDocument(document));
    }
    _refreshDigest();
  }

  void _refreshDigest() => unawaited(
    _bestEffort(() => _notifications.scheduleWeeklyDigest(_documents)),
  );

  @override
  Future<void> addDocument(DocumentItem document) => _write(() async {
    await _db.upsertDocument(document);
    _documents.insert(0, document);
    notifyListeners();
    await _schedule(document);
  });

  @override
  Future<void> toggleFavorite(DocumentItem document) => _write(() async {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index == -1) return;
    final current = _documents[index];
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    await _db.upsertDocument(updated);
    _documents[index] = updated;
    notifyListeners();
  });
  @override
  Future<void> updateDocument(DocumentItem updated) => _write(() async {
    final index = _documents.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;
    await _db.upsertDocument(updated);
    _documents[index] = updated;
    notifyListeners();
    await _schedule(updated);
  });
  @override
  Future<void> trashDocument(String id) => _write(() async {
    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final trashed = _documents[index].markDeleted(DateTime.now());
    await _db.softDeleteDocument(id, trashed.deletedAt!);
    _documents.removeAt(index);
    _trashedDocuments.insert(0, trashed);
    notifyListeners();
    await _cancel(id);
    _refreshDigest();
  });
  @override
  Future<void> trashDocuments(Iterable<String> ids) => _write(() async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;
    final now = DateTime.now();
    final trashed = <DocumentItem>[];
    for (final id in idSet) {
      final index = _documents.indexWhere((d) => d.id == id);
      if (index == -1) continue;
      trashed.add(_documents[index].markDeleted(now));
    }
    if (trashed.isEmpty) return;
    await _db.softDeleteDocuments(idSet, now);
    _documents.removeWhere((d) => idSet.contains(d.id));
    _trashedDocuments.insertAll(0, trashed);
    notifyListeners();
    for (final document in trashed) {
      await _cancel(document.id);
    }
    _refreshDigest();
  });
  @override
  Future<void> restoreDocument(String id) => _write(() async {
    final index = _trashedDocuments.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final restored = _trashedDocuments[index].restored();
    await _db.restoreDocument(id);
    _trashedDocuments.removeAt(index);
    final insertAt = _documents.indexWhere(
      (d) => d.createdAt.isBefore(restored.createdAt),
    );
    _documents.insert(insertAt == -1 ? _documents.length : insertAt, restored);
    notifyListeners();
    await _schedule(restored);
  });
  @override
  Future<void> permanentlyDeleteDocument(String id) => _write(() async {
    if (!_trashedDocuments.any((d) => d.id == id)) return;
    await _db.deleteDocument(id);
    _trashedDocuments.removeWhere((d) => d.id == id);
    notifyListeners();
    await _cancel(id);
  });
  @override
  Future<void> emptyTrash() => _write(() async {
    final ids = _trashedDocuments.map((d) => d.id).toList();
    if (ids.isEmpty) return;
    await _db.deleteDocuments(ids);
    _trashedDocuments.clear();
    notifyListeners();
    for (final id in ids) {
      await _cancel(id);
    }
  });
  @override
  int countForCategory(String categoryId) =>
      _documents.where((d) => d.categoryId == categoryId).length;
}
