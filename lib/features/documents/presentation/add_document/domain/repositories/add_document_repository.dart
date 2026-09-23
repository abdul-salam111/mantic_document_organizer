import '../../../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/add_document_params.dart';
import '../entities/add_document_entity.dart';

abstract interface class IAddDocumentRepository {
  Future<Result<AddDocumentEntity>> addDocument({
    required AddDocumentParams params,
  });
}
