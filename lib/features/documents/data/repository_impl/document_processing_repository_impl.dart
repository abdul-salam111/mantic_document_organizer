import '../../domain/entities/document_item.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/document_pdf_exporter.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/document_suggestion.dart';
import '../../domain/repositories/document_processing_repository.dart';
import '../datasources/attachment_local_datasource.dart';
import '../../../../core/ocr/ocr_service.dart';
import '../../../../core/ai/ai_document_service.dart';

class DocumentProcessingRepositoryImpl
    implements IDocumentProcessingRepository {
  final AttachmentLocalDataSource _attachments;
  final OcrService _ocr;
  final AiDocumentService _ai;
  DocumentProcessingRepositoryImpl(this._attachments, this._ocr, this._ai);
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
}
