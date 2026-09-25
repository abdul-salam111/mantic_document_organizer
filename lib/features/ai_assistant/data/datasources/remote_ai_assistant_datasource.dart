import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/ai_assistant_params.dart';
import '../models/response_models/ai_assistant_response.dart';

abstract interface class IRemoteAiAssistantDataSource {
  Future<AiAssistantResponse> performAction({
    required AiAssistantParams params,
  });
}

class RemoteAiAssistantDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteAiAssistantDataSource {
  RemoteAiAssistantDataSourceImpl({required super.dioHelper});

  @override
  Future<AiAssistantResponse> performAction({
    required AiAssistantParams params,
  }) async {
    return post(
      url: ApiEndPoints.aiAssistant,
      parser: (json) => AiAssistantResponse.fromJson(json),
      body: params.toJson(),
    );
  }
}
