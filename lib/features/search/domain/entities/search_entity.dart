/// The domain-layer representation this feature works with, decoupled
/// from `SearchResponse`'s API response shape (mapped at the repository
/// boundary — see `SearchRepositoryImpl`).
class SearchEntity {
  final String? id;
  final String? name;
  final String? description;

  const SearchEntity({this.id, this.name, this.description});
}
