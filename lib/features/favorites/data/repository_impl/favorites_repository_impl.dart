import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_favorites_datasource.dart';
import '../../domain/entities/favorites_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl extends BaseRepository
    implements IFavoritesRepository {
  final IRemoteFavoritesDataSource dataSource;

  FavoritesRepositoryImpl({required this.dataSource});

  @override
  Future<Result<List<FavoritesEntity>>> getFavorites() async {
    final result = await execute(call: () => dataSource.getFavorites());
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (responses) => Success(
        responses
            .map(
              (response) => FavoritesEntity(
                id: response.id,
                name: response.name,
                description: response.description,
              ),
            )
            .toList(),
      ),
    );
  }
}
