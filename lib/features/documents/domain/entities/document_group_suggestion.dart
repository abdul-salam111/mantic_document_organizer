import 'document_suggestion.dart';

/// One proposed document out of a batch of OCR'd files sent to
/// [AiDocumentService.analyzeGroups] -- [memberIndices] names which of the
/// input `ocrTexts` (by position) the AI believes are pages of the same
/// physical document (e.g. the front and back of one ID card). The
/// remaining fields mirror [AiDocumentSuggestion] exactly, since a group is
/// otherwise scored/suggested the same way a single document is.
class DocumentGroupSuggestion {
  final List<int> memberIndices;
  final bool isDocument;
  final String? title;
  final String? categoryName;
  final String description;
  final List<String> tags;
  final bool isExpirable;
  final DateTime? expiryDate;

  const DocumentGroupSuggestion({
    required this.memberIndices,
    this.isDocument = true,
    this.title,
    this.categoryName,
    this.description = '',
    this.tags = const [],
    this.isExpirable = false,
    this.expiryDate,
  });

  /// Lets grouping reuse the same category-lookup/tag-validation logic
  /// `BulkImportViewModel._applySuggestion` already has for a single
  /// document's AI suggestion.
  AiDocumentSuggestion toAiDocumentSuggestion() => AiDocumentSuggestion(
    isDocument: isDocument,
    title: title,
    categoryName: categoryName,
    description: description,
    tags: tags,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
  );
}
