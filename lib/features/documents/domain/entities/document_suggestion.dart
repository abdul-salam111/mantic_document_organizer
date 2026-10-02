class AiDocumentSuggestion {
  // Add Document's own manual-pick flow never reads this field -- a file
  // the user deliberately scanned/picked is already known to be a
  // document. Bulk Import's discovery flow is the one caller that treats
  // this as the actual inclusion decision, not just a suggestion.
  final bool isDocument;
  final String? title;
  final String? categoryName;
  final String description;
  final List<String> tags;
  final bool isExpirable;
  final DateTime? expiryDate;

  const AiDocumentSuggestion({
    this.isDocument = true,
    this.title,
    this.categoryName,
    this.description = '',
    this.tags = const [],
    this.isExpirable = false,
    this.expiryDate,
  });
}
