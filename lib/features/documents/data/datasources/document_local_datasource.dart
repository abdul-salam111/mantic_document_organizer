import '../../../../core/database/app_database.dart';
import '../../domain/entities/document_item.dart';

abstract interface class DocumentLocalDataSource {
  Future<List<DocumentItem>> fetchDocuments();
  Future<List<DocumentItem>> fetchTrashedDocuments();
  Future<void> purgeExpiredTrash(Duration retention);
  Future<void> upsertDocument(DocumentItem item);
  Future<void> softDeleteDocument(String id, DateTime date);
  Future<void> restoreDocument(String id);
  Future<void> deleteDocument(String id);
  Future<void> deleteDocuments(Iterable<String> ids);
}

class SqliteDocumentDataSource implements DocumentLocalDataSource {
  final AppDatabase _database;
  SqliteDocumentDataSource(this._database);
  @override
  Future<List<DocumentItem>> fetchDocuments() => _database.fetchDocuments();
  @override
  Future<List<DocumentItem>> fetchTrashedDocuments() =>
      _database.fetchTrashedDocuments();
  @override
  Future<void> purgeExpiredTrash(Duration retention) =>
      _database.purgeExpiredTrash(retention);
  @override
  Future<void> upsertDocument(DocumentItem item) =>
      _database.upsertDocument(item);
  @override
  Future<void> softDeleteDocument(String id, DateTime date) =>
      _database.softDeleteDocument(id, date);
  @override
  Future<void> restoreDocument(String id) => _database.restoreDocument(id);
  @override
  Future<void> deleteDocument(String id) => _database.deleteDocument(id);
  @override
  Future<void> deleteDocuments(Iterable<String> ids) =>
      _database.deleteDocuments(ids);
}
