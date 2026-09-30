import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';

class TrashViewModel extends ChangeNotifier {
  final DocumentUseCases _documentUseCases;

  TrashViewModel({required DocumentUseCases documentUseCases})
    : _documentUseCases = documentUseCases {
    _documentUseCases.addListener(notifyListeners);
  }

  /// Newest-deleted first.
  List<DocumentItem> get documents => _documentUseCases.trashedDocuments;

  Future<void> restore(DocumentItem document) =>
      _documentUseCases.restoreDocument(document.id);

  Future<void> deleteForever(DocumentItem document) =>
      _documentUseCases.permanentlyDeleteDocument(document.id);

  Future<void> emptyTrash() => _documentUseCases.emptyTrash();

  @override
  void dispose() {
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
