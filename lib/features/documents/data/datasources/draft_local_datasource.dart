import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/document_draft.dart';

abstract interface class DraftLocalDataSource {
  Future<List<DocumentDraft>> read();
  Future<void> save(DocumentDraft draft);
  Future<void> discard(String id);
  Future<List<String>> missingFiles(DocumentDraft draft);
}

class SqliteDraftDataSource implements DraftLocalDataSource {
  final AppDatabase _db;
  SqliteDraftDataSource(this._db);
  @override
  Future<List<DocumentDraft>> read() => _db.fetchDrafts();
  @override
  Future<void> save(DocumentDraft draft) => _db.upsertDraft(draft);
  @override
  Future<List<String>> missingFiles(DocumentDraft draft) async => [
    for (final path in draft.document.filePaths)
      if (!await File(path).exists()) path,
  ];

  @override
  Future<void> discard(String id) async {
    final paths = await _db.deleteDraft(id);
    final root = p.join((await getApplicationDocumentsDirectory()).path, 'documents');
    for (final path in paths) {
      // Only regular files in our attachment directory, never source files,
      // symlinks, or attachments still referenced by saved documents/drafts.
      if (!p.isWithin(root, path)) continue;
      try {
        if (await FileSystemEntity.type(path, followLinks: false) == FileSystemEntityType.file) {
          await File(path).delete();
        }
      } on FileSystemException {
        // Metadata removal succeeded. An orphan can be cleaned up later.
      }
    }
  }
}
