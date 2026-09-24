import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/document_params.dart';
import '../models/response_models/document_response.dart';

abstract interface class IRemoteDocumentDataSource {
  Future<DocumentResponse> addDocument({required DocumentParams params});
}

class RemoteDocumentDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteDocumentDataSource {
  RemoteDocumentDataSourceImpl({required super.dioHelper});

  @override
  Future<DocumentResponse> addDocument({required DocumentParams params}) async {
    return post(
      url: ApiEndPoints.addDocument,
      parser: (json) => DocumentResponse.fromJson(json),
      body: params.toJson(),
    );
  }
}
