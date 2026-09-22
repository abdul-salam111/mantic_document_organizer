import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_add_document_datasource.dart';
import '../models/request_models/add_document_params.dart';
import '../../domain/entities/add_document_entity.dart';
import '../../domain/repositories/add_document_repository.dart';

class AddDocumentRepositoryImpl extends BaseRepository
    implements IAddDocumentRepository {
  final IRemoteAddDocumentDataSource dataSource;

  AddDocumentRepositoryImpl({required this.dataSource});

  @override
  Future<Result<AddDocumentEntity>> addDocument({
    required AddDocumentParams params,
  }) async {
    final result = await execute(
      call: () => dataSource.addDocument(params: params),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (response) => Success(
        AddDocumentEntity(
          id: response.id,
          name: response.name,
          description: response.description,
        ),
      ),
    );
  }
}
