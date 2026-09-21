/// The domain-layer representation this feature works with, decoupled
/// from `{{className}}Response`'s API response shape (mapped at the
/// repository boundary — see `{{className}}RepositoryImpl`).
class {{className}}Entity {
  final String? id;
  final String? name;
  final String? description;

  const {{className}}Entity({this.id, this.name, this.description});
}
