import 'package:mantic_doc_org/features/documents/domain/entities/document_policy.dart';
import '../entities/document_item.dart';
import '../repositories/document_repository.dart';

class DocumentUseCases {
  final IDocumentRepository _repository;
  DocumentUseCases(this._repository);
  static const trashRetentionPeriod = DocumentPolicy.trashRetentionPeriod;
  static const digestWindowDays = DocumentPolicy.digestWindowDays;
  void addListener(void Function() listener) =>
      _repository.addListener(listener);
  void removeListener(void Function() listener) =>
      _repository.removeListener(listener);
  List<DocumentItem> get documents => _repository.documents;
  List<DocumentItem> get trashedDocuments => _repository.trashedDocuments;
  Future<void> init() => _repository.init();
  Future<void> addDocument(DocumentItem document) =>
      _repository.addDocument(document);
  Future<void> toggleFavorite(DocumentItem document) =>
      _repository.toggleFavorite(document);
  Future<void> updateDocument(DocumentItem updated) =>
      _repository.updateDocument(updated);
  Future<void> trashDocument(String id) => _repository.trashDocument(id);
  Future<void> restoreDocument(String id) => _repository.restoreDocument(id);
  Future<void> permanentlyDeleteDocument(String id) =>
      _repository.permanentlyDeleteDocument(id);
  Future<void> emptyTrash() => _repository.emptyTrash();
  int countForCategory(String categoryId) =>
      _repository.countForCategory(categoryId);
  List<DocumentItem> expiringSoon({DateTime? at}) {
    final now = at ?? DateTime.now();
    final windowEnd = now.add(const Duration(days: digestWindowDays));
    final matches = documents
        .where(
          (d) =>
              d.isExpirable &&
              d.expiryDate != null &&
              d.expiryDate!.isAfter(now) &&
              d.expiryDate!.isBefore(windowEnd),
        )
        .toList();
    matches.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return matches;
  }
}
