import '../entities/document_item.dart';
import '../entities/attachment_item.dart';
import '../entities/document_suggestion.dart';
import '../repositories/document_processing_repository.dart';

class DocumentProcessingUseCases {
  final IDocumentProcessingRepository _repository;
  DocumentProcessingUseCases(this._repository);
  Future<AttachmentSelection> pickFromCamera() => _repository.pickFromCamera();
  Future<AttachmentSelection> pickFromGallery() =>
      _repository.pickFromGallery();
  Future<AttachmentSelection> pickFile() => _repository.pickFile();
  Future<AttachmentSelection> addSharedFiles(List<String> sourcePaths) =>
      _repository.addSharedFiles(sourcePaths);
  Future<String> extractText(String path) => _repository.extractText(path);
  Future<AiDocumentSuggestion?> analyze({
    required String ocrText,
    required List<String> availableCategories,
  }) => _repository.analyze(
    ocrText: ocrText,
    availableCategories: availableCategories,
  );
  Future<void> share(DocumentItem document) => _repository.share(document);
  Future<void> exportPdf(DocumentItem document) =>
      _repository.exportPdf(document);
  Future<void> shareFile(String path) => _repository.shareFile(path);
  Future<void> shareFiles(List<String> paths) => _repository.shareFiles(paths);
  Future<void> shareAsPdf(List<String> paths, String title) =>
      _repository.shareAsPdf(paths, title: title);
  Future<void> shareAsImages(List<String> paths) =>
      _repository.shareAsImages(paths);
  Future<void> exportPagesAsPdf(List<String> paths, String title) =>
      _repository.exportPagesAsPdf(paths, title: title);
  Future<void> saveToGallery(List<String> paths) =>
      _repository.saveToGallery(paths);
}
