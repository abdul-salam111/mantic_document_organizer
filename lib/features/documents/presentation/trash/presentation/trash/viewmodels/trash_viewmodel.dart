import 'package:flutter/foundation.dart';

import '../../../../../../home/home_exports.dart';

/// No real document data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section) — this reads/writes straight through the shared
/// [DocumentLocalStore], same as document_viewer/category_documents.
class TrashViewModel extends ChangeNotifier {
  final DocumentLocalStore _documentStore;

  TrashViewModel({required DocumentLocalStore documentStore})
    : _documentStore = documentStore {
    _documentStore.addListener(notifyListeners);
  }

  /// Newest-deleted first.
  List<DocumentItem> get documents => _documentStore.trashedDocuments;

  void restore(DocumentItem document) =>
      _documentStore.restoreDocument(document.id);

  void deleteForever(DocumentItem document) =>
      _documentStore.permanentlyDeleteDocument(document.id);

  void emptyTrash() => _documentStore.emptyTrash();

  @override
  void dispose() {
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
