import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/response_models/favorites_response.dart';

abstract interface class IRemoteFavoritesDataSource {
  Future<List<FavoritesResponse>> getFavorites();
}

class RemoteFavoritesDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteFavoritesDataSource {
  RemoteFavoritesDataSourceImpl({required super.dioHelper});

  @override
  Future<List<FavoritesResponse>> getFavorites() async {
    return getList(
      url: ApiEndPoints.favorites,
      parser: (json) => FavoritesResponse.fromJson(json),
    );
  }
}
