import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_search_datasource.dart';
import '../models/request_models/search_params.dart';
import '../../domain/entities/search_entity.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl extends BaseRepository
    implements ISearchRepository {
  final IRemoteSearchDataSource dataSource;

  SearchRepositoryImpl({required this.dataSource});

  @override
  Future<Result<List<SearchEntity>>> performAction({
    required SearchParams params,
  }) async {
    final result = await execute(
      call: () => dataSource.performAction(params: params),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (responses) => Success(
        responses
            .map(
              (response) => SearchEntity(
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
