import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/search_params.dart';
import '../entities/search_entity.dart';

abstract interface class ISearchRepository {
  Future<Result<List<SearchEntity>>> performAction({
    required SearchParams params,
  });
}
