import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/document_params.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class DocumentUsecase implements Usecase<DocumentEntity, DocumentParams> {
  final IDocumentRepository repository;

  DocumentUsecase({required this.repository});

  @override
  Future<Result<DocumentEntity>> call(DocumentParams params) {
    return repository.addDocument(params: params);
  }
}
