import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_ai_assistant_datasource.dart';
import '../models/request_models/ai_assistant_params.dart';
import '../../domain/entities/ai_assistant_entity.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

class AiAssistantRepositoryImpl extends BaseRepository
    implements IAiAssistantRepository {
  final IRemoteAiAssistantDataSource dataSource;

  AiAssistantRepositoryImpl({required this.dataSource});

  @override
  Future<Result<AiAssistantEntity>> performAction({
    required AiAssistantParams params,
  }) async {
    final result = await execute(
      call: () => dataSource.performAction(params: params),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (response) => Success(
        AiAssistantEntity(
          id: response.id,
          name: response.name,
          description: response.description,
        ),
      ),
    );
  }
}
