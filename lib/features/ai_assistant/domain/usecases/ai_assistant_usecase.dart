import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/ai_assistant_params.dart';
import '../entities/ai_assistant_entity.dart';
import '../repositories/ai_assistant_repository.dart';

class AiAssistantUsecase
    implements Usecase<AiAssistantEntity, AiAssistantParams> {
  final IAiAssistantRepository repository;

  AiAssistantUsecase({required this.repository});

  @override
  Future<Result<AiAssistantEntity>> call(AiAssistantParams params) {
    return repository.performAction(params: params);
  }
}
