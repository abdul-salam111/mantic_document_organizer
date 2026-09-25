/// The domain-layer representation this feature works with, decoupled
/// from `AiAssistantResponse`'s API response shape (mapped at the
/// repository boundary — see `AiAssistantRepositoryImpl`).
///
/// This is the original brick-scaffolded REST plumbing — unused (see the
/// doc comment on `aiAssistantDependencies()` in injection_container.dart
/// and on `AiAssistantViewModel`): this feature's real domain type is
/// `ChatMessage` (chat_message.dart), and its real "backend" is the
/// OpenRouter call inside `AiChatService` (lib/core/ai), not this REST
/// layer. Kept registered/compiling for consistency with how
/// documents/add_document leave their own unused REST scaffolding intact.
class AiAssistantEntity {
  final String? id;
  final String? name;
  final String? description;

  const AiAssistantEntity({this.id, this.name, this.description});
}
