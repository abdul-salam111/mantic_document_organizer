import '../../domain/entities/document_item.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/document_pdf_exporter.dart';
import '../../../../core/utils/document_page_rasterizer.dart';
import '../../../../core/gallery/gallery_saver_service.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/document_suggestion.dart';
import '../../domain/entities/document_group_suggestion.dart';
import '../../domain/repositories/document_processing_repository.dart';
import '../datasources/attachment_local_datasource.dart';
import '../../../../core/ocr/ocr_service.dart';
import '../../../../core/ai/ai_document_service.dart';

class DocumentProcessingRepositoryImpl
    implements IDocumentProcessingRepository {
  final AttachmentLocalDataSource _attachments;
  final OcrService _ocr;
  final AiDocumentService _ai;
  final GallerySaverService _gallery;
  DocumentProcessingRepositoryImpl(
    this._attachments,
    this._ocr,
    this._ai,
    this._gallery,
  );
  @override
  Future<AttachmentSelection> pickFromCamera() => _attachments.pickFromCamera();
  @override
  Future<AttachmentSelection> pickFromGallery() =>
      _attachments.pickFromGallery();
  @override
  Future<AttachmentSelection> pickFile() => _attachments.pickFile();
  @override
  Future<AttachmentSelection> addSharedFiles(List<String> sourcePaths) =>
      _attachments.addSharedFiles(sourcePaths);
  @override
  Future<String> extractText(String path) => _ocr.extractText(path);
  @override
  Future<AiDocumentSuggestion?> analyze({
    required String ocrText,
    required List<String> availableCategories,
  }) => _ai.analyze(ocrText: ocrText, availableCategories: availableCategories);
  @override
  Future<List<DocumentGroupSuggestion>?> analyzeGroups({
    required List<String> ocrTexts,
    required List<String> availableCategories,
  }) async {
    final raw = await _ai.analyzeGroups(
      ocrTexts: ocrTexts,
      availableCategories: availableCategories,
    );
    if (raw == null) return null;
    return _repairGroups(raw, ocrTexts.length);
  }

  /// The AI can't be trusted to partition `0..n-1` perfectly -- it may skip
  /// an index, duplicate one across groups, or return one out of range.
  /// This guarantees every caller gets a result that covers every input
  /// index exactly once, so nothing downstream has to re-validate it: a
  /// duplicate/out-of-range index is dropped from the later group that
  /// claimed it, and any index never claimed becomes its own singleton
  /// group.
  List<DocumentGroupSuggestion> _repairGroups(
    List<DocumentGroupSuggestion> groups,
    int count,
  ) {
    final seen = <int>{};
    final repaired = <DocumentGroupSuggestion>[];
    for (final group in groups) {
      final members = [
        for (final index in group.memberIndices)
          if (index >= 0 && index < count && seen.add(index)) index,
      ];
      if (members.isEmpty) continue;
      repaired.add(
        DocumentGroupSuggestion(
          memberIndices: members,
          isDocument: group.isDocument,
          title: group.title,
          categoryName: group.categoryName,
          description: group.description,
          tags: group.tags,
          isExpirable: group.isExpirable,
          expiryDate: group.expiryDate,
        ),
      );
    }
    for (var index = 0; index < count; index++) {
      if (seen.add(index)) {
        repaired.add(DocumentGroupSuggestion(memberIndices: [index]));
      }
    }
    return repaired;
  }

  @override
  Future<void> share(DocumentItem document) async {
    await SharePlus.instance.share(
      ShareParams(files: [for (final path in document.filePaths) XFile(path)]),
    );
  }

  @override
  Future<void> exportPdf(DocumentItem document) async {
    final path = await DocumentPdfExporter.export(document);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  @override
  Future<void> shareFile(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  @override
  Future<void> shareFiles(List<String> paths) async {
    await SharePlus.instance.share(
      ShareParams(files: [for (final path in paths) XFile(path)]),
    );
  }

  @override
  Future<void> shareAsPdf(List<String> paths, {required String title}) async {
    final combined = await DocumentPdfExporter.combine(paths, title);
    await SharePlus.instance.share(ShareParams(files: [XFile(combined)]));
  }

  @override
  Future<void> shareAsImages(List<String> paths) async {
    final images = await DocumentPageRasterizer.toImagePaths(paths);
    await shareFiles(images);
  }

  @override
  Future<void> exportPagesAsPdf(
    List<String> paths, {
    required String title,
  }) async {
    final files = await DocumentPdfExporter.exportEachPage(paths, title);
    await shareFiles(files);
  }

  @override
  Future<void> saveToGallery(List<String> paths) async {
    final images = await DocumentPageRasterizer.toImagePaths(paths);
    await _gallery.saveImages(images);
  }
}
