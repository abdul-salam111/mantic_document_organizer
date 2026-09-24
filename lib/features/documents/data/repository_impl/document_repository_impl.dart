import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_document_datasource.dart';
import '../models/request_models/document_params.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl extends BaseRepository
    implements IDocumentRepository {
  final IRemoteDocumentDataSource dataSource;

  DocumentRepositoryImpl({required this.dataSource});

  @override
  Future<Result<DocumentEntity>> addDocument({
    required DocumentParams params,
  }) async {
    final result = await execute(
      call: () => dataSource.addDocument(params: params),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (response) => Success(
        DocumentEntity(
          id: response.id,
          name: response.name,
          description: response.description,
        ),
      ),
    );
  }
}
