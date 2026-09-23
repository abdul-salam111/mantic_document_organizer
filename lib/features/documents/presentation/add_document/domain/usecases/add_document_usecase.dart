import '../../../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/add_document_params.dart';
import '../entities/add_document_entity.dart';
import '../repositories/add_document_repository.dart';

class AddDocumentUsecase
    implements Usecase<AddDocumentEntity, AddDocumentParams> {
  final IAddDocumentRepository repository;

  AddDocumentUsecase({required this.repository});

  @override
  Future<Result<AddDocumentEntity>> call(AddDocumentParams params) {
    return repository.addDocument(params: params);
  }
}
