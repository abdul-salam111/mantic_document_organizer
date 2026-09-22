import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/search_params.dart';
import '../entities/search_entity.dart';
import '../repositories/search_repository.dart';

class SearchUsecase implements Usecase<List<SearchEntity>, SearchParams> {
  final ISearchRepository repository;

  SearchUsecase({required this.repository});

  @override
  Future<Result<List<SearchEntity>>> call(SearchParams params) {
    return repository.performAction(params: params);
  }
}
