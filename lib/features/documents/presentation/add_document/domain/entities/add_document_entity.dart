/// The domain-layer representation this feature works with, decoupled
/// from `AddDocumentResponse`'s API response shape (mapped at the
/// repository boundary — see `AddDocumentRepositoryImpl`).
class AddDocumentEntity {
  final String? id;
  final String? name;
  final String? description;

  const AddDocumentEntity({this.id, this.name, this.description});
}
