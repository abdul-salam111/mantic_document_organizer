import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/document_params.dart';
import '../entities/document_entity.dart';

abstract interface class IDocumentRepository {
  Future<Result<DocumentEntity>> addDocument({required DocumentParams params});
}
