import 'package:mantic_doc_org/features/documents/domain/entities/attachment_item.dart';

enum CandidateProcessingState { queued, processing, ready, failed }

class BulkImportCandidate {
  final String id;
  final AttachmentItem attachment;
  final String title;
  final String categoryId;
  final List<String> tags;
  final String ocrText;
  final bool isSelected;
  final CandidateProcessingState state;
  final String? error;
  final bool hasUserEditedTitle;
  final bool hasUserEditedCategory;
  final bool hasUserEditedTags;
  final String description;
  final DateTime? expiryDate;
  final bool hasUserEditedDescription;
  final bool hasUserEditedExpiry;
  final String? importError;

  BulkImportCandidate({
    required this.id,
    required this.attachment,
    required this.title,
    required this.categoryId,
    List<String> tags = const [],
    this.ocrText = '',
    this.isSelected = true,
    this.state = CandidateProcessingState.queued,
    this.error,
    this.hasUserEditedTitle = false,
    this.hasUserEditedCategory = false,
    this.hasUserEditedTags = false,
    this.description = '',
    this.expiryDate,
    this.hasUserEditedDescription = false,
    this.hasUserEditedExpiry = false,
    this.importError,
  }) : tags = List.unmodifiable(tags);

  BulkImportCandidate copyWith({
    String? title,
    String? categoryId,
    List<String>? tags,
    String? ocrText,
    bool? isSelected,
    CandidateProcessingState? state,
    String? error,
    bool? hasUserEditedTitle,
    bool? hasUserEditedCategory,
    bool? hasUserEditedTags,
    String? description,
    DateTime? expiryDate,
    bool clearExpiry = false,
    bool? hasUserEditedDescription,
    bool? hasUserEditedExpiry,
    String? importError,
    bool clearImportError = false,
    bool clearError = false,
  }) => BulkImportCandidate(
    id: id,
    attachment: attachment,
    title: title ?? this.title,
    categoryId: categoryId ?? this.categoryId,
    tags: List.unmodifiable(tags ?? this.tags),
    ocrText: ocrText ?? this.ocrText,
    isSelected: isSelected ?? this.isSelected,
    state: state ?? this.state,
    error: clearError ? null : error ?? this.error,
    hasUserEditedTitle: hasUserEditedTitle ?? this.hasUserEditedTitle,
    hasUserEditedCategory: hasUserEditedCategory ?? this.hasUserEditedCategory,
    hasUserEditedTags: hasUserEditedTags ?? this.hasUserEditedTags,
    description: description ?? this.description,
    expiryDate: clearExpiry ? null : expiryDate ?? this.expiryDate,
    hasUserEditedDescription:
        hasUserEditedDescription ?? this.hasUserEditedDescription,
    hasUserEditedExpiry: hasUserEditedExpiry ?? this.hasUserEditedExpiry,
    importError: clearImportError ? null : importError ?? this.importError,
  );
}
