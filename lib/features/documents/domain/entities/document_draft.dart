import 'document_item.dart';

/// An unfinished new capture. Its stable ID becomes the saved document ID.
class DocumentDraft {
  final DocumentItem document;
  final DateTime updatedAt;
  final String pendingTag;
  final Map<String, String> ocrByPath;
  final List<String> ownedPaths;

  DocumentDraft({
    required this.document,
    required this.updatedAt,
    this.pendingTag = '',
    Map<String, String> ocrByPath = const {},
    List<String> ownedPaths = const [],
  }) : ocrByPath = Map.unmodifiable(ocrByPath),
       ownedPaths = List.unmodifiable(ownedPaths);

  String get id => document.id;
}
