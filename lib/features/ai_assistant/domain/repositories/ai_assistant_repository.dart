import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/ai_assistant_params.dart';
import '../entities/ai_assistant_entity.dart';

abstract interface class IAiAssistantRepository {
  Future<Result<AiAssistantEntity>> performAction({
    required AiAssistantParams params,
  });
}
