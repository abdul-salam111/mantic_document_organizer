import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/{{fileName}}_params.dart';
import '../models/response_models/{{fileName}}_response.dart';

abstract interface class IRemote{{className}}DataSource {
  Future<{{className}}Response> performAction({required {{className}}Params params});
}

class Remote{{className}}DataSourceImpl extends BaseRemoteDatasource
    implements IRemote{{className}}DataSource {
  Remote{{className}}DataSourceImpl({required super.dioHelper});

  @override
  Future<{{className}}Response> performAction({
    required {{className}}Params params,
  }) async {
    return post(
      url: ApiEndPoints.{{camelName}},
      parser: (json) => {{className}}Response.fromJson(json),
      body: params.toJson(),
    );
  }
}
