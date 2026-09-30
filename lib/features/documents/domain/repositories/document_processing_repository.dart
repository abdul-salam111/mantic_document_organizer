import '../entities/document_item.dart';
import '../entities/attachment_item.dart';
import '../entities/document_suggestion.dart';

abstract interface class IDocumentProcessingRepository {
  Future<AttachmentSelection> pickFromCamera();
  Future<AttachmentSelection> pickFromGallery();
  Future<AttachmentSelection> pickFile();
  Future<AttachmentSelection> addSharedFiles(List<String> sourcePaths);
  Future<String> extractText(String path);
  Future<AiDocumentSuggestion?> analyze({
    required String ocrText,
    required List<String> availableCategories,
  });
  Future<void> share(DocumentItem document);
  Future<void> exportPdf(DocumentItem document);
  Future<void> shareFile(String path);
}
