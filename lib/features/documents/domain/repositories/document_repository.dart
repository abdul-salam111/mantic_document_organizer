import '../entities/document_item.dart';

abstract interface class IDocumentRepository {
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  List<DocumentItem> get documents;
  List<DocumentItem> get trashedDocuments;
  Future<void> init();
  Future<void> addDocument(DocumentItem document);
  Future<void> toggleFavorite(DocumentItem document);
  Future<void> updateDocument(DocumentItem updated);
  Future<void> trashDocument(String id);
  Future<void> trashDocuments(Iterable<String> ids);
  Future<void> restoreDocument(String id);
  Future<void> permanentlyDeleteDocument(String id);
  Future<void> emptyTrash();
  int countForCategory(String categoryId);
}
