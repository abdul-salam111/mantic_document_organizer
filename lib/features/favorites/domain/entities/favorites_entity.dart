/// The domain-layer representation this feature works with, decoupled
/// from `FavoritesResponse`'s API response shape (mapped at the
/// repository boundary — see `FavoritesRepositoryImpl`).
class FavoritesEntity {
  final String? id;
  final String? name;
  final String? description;

  const FavoritesEntity({this.id, this.name, this.description});
}
