import '../../../../core/shared/shared_exports.dart';
import '../entities/favorites_entity.dart';
import '../repositories/favorites_repository.dart';

class FavoritesUsecase implements Usecase<List<FavoritesEntity>, NoParams> {
  final IFavoritesRepository repository;

  FavoritesUsecase({required this.repository});

  @override
  Future<Result<List<FavoritesEntity>>> call(NoParams params) {
    return repository.getFavorites();
  }
}
