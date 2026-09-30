class AiDocumentSuggestion {
  final String? title;
  final String? categoryName;
  final String description;
  final List<String> tags;
  final bool isExpirable;
  final DateTime? expiryDate;

  const AiDocumentSuggestion({
    this.title,
    this.categoryName,
    this.description = '',
    this.tags = const [],
    this.isExpirable = false,
    this.expiryDate,
  });
}
