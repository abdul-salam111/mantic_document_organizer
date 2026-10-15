import '../entities/document_item.dart';
import '../entities/attachment_item.dart';
import '../entities/document_suggestion.dart';
import '../entities/document_group_suggestion.dart';

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

  /// Clusters several OCR'd files into logical documents in one AI call --
  /// used when importing a batch (Bulk Import's gallery scan, or several
  /// files shared in at once) rather than one document at a time. The
  /// result always partitions every index of [ocrTexts] into exactly one
  /// group (see the impl's repair step); only a hard AI/network failure
  /// returns null.
  Future<List<DocumentGroupSuggestion>?> analyzeGroups({
    required List<String> ocrTexts,
    required List<String> availableCategories,
  });
  Future<void> share(DocumentItem document);
  Future<void> exportPdf(DocumentItem document);
  Future<void> shareFile(String path);

  /// Native OS share sheet with every file in [paths] attached.
  Future<void> shareFiles(List<String> paths);

  /// Combines [paths] into a single PDF (rasterizing any real PDF pages
  /// among them) and shares it.
  Future<void> shareAsPdf(List<String> paths, {required String title});

  /// Shares [paths] as separate images, rasterizing any PDF pages first.
  Future<void> shareAsImages(List<String> paths);

  /// Exports every page in [paths] as its own separate PDF file, then
  /// shares all of them together.
  Future<void> exportPagesAsPdf(List<String> paths, {required String title});

  /// Saves [paths] to the device photo gallery, rasterizing any PDF pages
  /// first.
  Future<void> saveToGallery(List<String> paths);
}
