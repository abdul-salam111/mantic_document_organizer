/// The domain-layer representation the documents feature works with,
/// decoupled from `DocumentResponse`'s API response shape (mapped at the
/// repository boundary — see `DocumentRepositoryImpl`). Shared by every
/// page under this feature (add_document, category_documents, ...) rather
/// than each page carrying its own copy.
class DocumentEntity {
  final String? id;
  final String? name;
  final String? description;

  const DocumentEntity({this.id, this.name, this.description});
}
