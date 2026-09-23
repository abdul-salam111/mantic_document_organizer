import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/add_document_params.dart';
import '../models/response_models/add_document_response.dart';

abstract interface class IRemoteAddDocumentDataSource {
  Future<AddDocumentResponse> addDocument({required AddDocumentParams params});
}

class RemoteAddDocumentDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteAddDocumentDataSource {
  RemoteAddDocumentDataSourceImpl({required super.dioHelper});

  @override
  Future<AddDocumentResponse> addDocument({
    required AddDocumentParams params,
  }) async {
    return post(
      url: ApiEndPoints.addDocument,
      parser: (json) => AddDocumentResponse.fromJson(json),
      body: params.toJson(),
    );
  }
}
