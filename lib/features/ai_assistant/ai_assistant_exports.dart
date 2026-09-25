// Barrel export for the ai_assistant feature — this is what OTHER
// features/core files import to reach ai_assistant's public API (e.g. its
// page for routing, or its models for a DI registration). Files *inside*
// the ai_assistant feature should import each other with relative paths,
// not this file.
export 'data/datasources/remote_ai_assistant_datasource.dart';
export 'data/models/request_models/ai_assistant_params.dart';
export 'data/models/response_models/ai_assistant_response.dart';
export 'data/repository_impl/ai_assistant_repository_impl.dart';
export 'domain/entities/ai_assistant_entity.dart';
export 'domain/entities/chat_message.dart';
export 'domain/repositories/ai_assistant_repository.dart';
export 'domain/usecases/ai_assistant_usecase.dart';
export 'presentation/ai_assistant/views/ai_assistant_view.dart';
export 'presentation/ai_assistant/viewmodels/ai_assistant_viewmodel.dart';
