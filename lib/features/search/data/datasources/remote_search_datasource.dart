import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/search_params.dart';
import '../models/response_models/search_response.dart';

abstract interface class IRemoteSearchDataSource {
  Future<List<SearchResponse>> performAction({required SearchParams params});
}

class RemoteSearchDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteSearchDataSource {
  RemoteSearchDataSourceImpl({required super.dioHelper});

  @override
  Future<List<SearchResponse>> performAction({
    required SearchParams params,
  }) async {
    return getList(
      url: ApiEndPoints.search,
      parser: (json) => SearchResponse.fromJson(json),
      queryParams: params.toJson(),
    );
  }
}
