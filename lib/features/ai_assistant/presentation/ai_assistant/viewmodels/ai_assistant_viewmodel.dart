import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../../core/ai/ai_exports.dart';
import '../../../domain/entities/chat_message.dart';

class AiAssistantViewModel extends ChangeNotifier {
  final DocumentUseCases _documentUseCases;
  final AiChatService _aiChatService;

  AiAssistantViewModel({
    required DocumentUseCases documentUseCases,
    required AiChatService aiChatService,
  }) : _documentUseCases = documentUseCases,
       _aiChatService = aiChatService;

  /// Set once by the view right after creation (from AppLocalizations) —
  /// keeps this ViewModel free of BuildContext, same reason
  /// AddDocumentViewModel never imports AppLocalizations either. Shown as
  /// the assistant's reply whenever [AiChatService.ask] returns null
  /// (offline, API error, bad response — all indistinguishable by design).
  String failureText = '';

  final TextEditingController inputController = TextEditingController();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isSending = false;
  bool get isSending => _isSending;

  /// How many completed question/answer pairs to keep sending as context
  /// on every subsequent question — bounds token growth on a long
  /// conversation instead of resending the entire history forever.
  static const int _maxHistoryExchanges = 6;

  List<ChatExchange> get _recentHistory {
    final exchanges = <ChatExchange>[];
    String? pendingQuestion;
    for (final message in _messages) {
      if (message.role == ChatRole.user) {
        pendingQuestion = message.text;
      } else if (!message.isError && pendingQuestion != null) {
        exchanges.add(
          ChatExchange(question: pendingQuestion, answer: message.text),
        );
        pendingQuestion = null;
      }
    }
    if (exchanges.length <= _maxHistoryExchanges) return exchanges;
    return exchanges.sublist(exchanges.length - _maxHistoryExchanges);
  }

  Future<void> send() async {
    final question = inputController.text.trim();
    if (question.isEmpty || _isSending) return;

    inputController.clear();
    final history = _recentHistory;
    _messages.add(
      ChatMessage(
        id: generateLocalId(),
        role: ChatRole.user,
        text: question,
        createdAt: DateTime.now(),
      ),
    );
    _isSending = true;
    notifyListeners();

    final result = await _aiChatService.ask(
      question: question,
      documents: _documentUseCases.documents,
      history: history,
    );

    _messages.add(
      result != null
          ? ChatMessage(
              id: generateLocalId(),
              role: ChatRole.assistant,
              text: result.answer,
              documentIds: result.documentIds,
              createdAt: DateTime.now(),
            )
          : ChatMessage(
              id: generateLocalId(),
              role: ChatRole.assistant,
              text: failureText,
              isError: true,
              createdAt: DateTime.now(),
            ),
    );
    _isSending = false;
    notifyListeners();
  }

  DocumentItem? documentById(String id) {
    for (final document in _documentUseCases.documents) {
      if (document.id == id) return document;
    }
    return null;
  }
}
