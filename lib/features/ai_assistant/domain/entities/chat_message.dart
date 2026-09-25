enum ChatRole { user, assistant }

/// One message in the assistant conversation — either something the user
/// typed, or the assistant's reply. In-memory only: this screen's
/// conversation resets when it's popped and reopened, matching every other
/// feature in this app (there's no persistence layer yet).
class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;

  /// Document ids (`DocumentItem.id`) this message references — always
  /// empty for a user message. [AiAssistantView] resolves each one back to
  /// a `DocumentItem` via `DocumentLocalStore` when rendering a reference
  /// card; an id that no longer resolves (e.g. the document was deleted
  /// since) is silently skipped rather than shown as broken.
  final List<String> documentIds;

  /// True for an assistant message that represents a failure (offline, API
  /// error) rather than a real answer — styled distinctly so it doesn't
  /// read as if the assistant genuinely didn't know the answer.
  final bool isError;

  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.documentIds = const [],
    this.isError = false,
    required this.createdAt,
  });
}
