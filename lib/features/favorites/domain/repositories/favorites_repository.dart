import '../../../../core/shared/shared_exports.dart';
import '../entities/favorites_entity.dart';

abstract interface class IFavoritesRepository {
  Future<Result<List<FavoritesEntity>>> getFavorites();
}
