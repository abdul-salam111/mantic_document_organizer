import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../../core/ai/ai_exports.dart';
import '../../../../../core/speech/speech_to_text_service.dart';
import '../../../domain/entities/chat_message.dart';

class AiAssistantViewModel extends ChangeNotifier {
  final DocumentUseCases _documentUseCases;
  final AiChatService _aiChatService;
  final SpeechToTextService _speechToText;

  AiAssistantViewModel({
    required DocumentUseCases documentUseCases,
    required AiChatService aiChatService,
    required SpeechToTextService speechToText,
  }) : _documentUseCases = documentUseCases,
       _aiChatService = aiChatService,
       _speechToText = speechToText;

  /// Both set once by the view right after creation (from
  /// AppLocalizations) — keeps this ViewModel free of BuildContext, same
  /// reason AddDocumentViewModel never imports AppLocalizations either.
  /// [failureText] is shown whenever [AiChatService.ask] returns null for
  /// any reason other than being offline (API error, bad response — still
  /// indistinguishable from each other by design); [offlineText] is shown
  /// instead when [AiChatService.isOffline] catches it first.
  String failureText = '';
  String offlineText = '';

  final TextEditingController inputController = TextEditingController();

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Starts listening and fills [inputController] with the recognized
  /// text as it's heard — never auto-sends, the user still taps Send.
  /// Returns false if listening couldn't even start (mic/speech
  /// permission denied, or no recognizer on this device) so the view can
  /// show an error toast; relies on [SpeechToTextService.startListening]'s
  /// contract that its `onDone` callback fires exactly once per attempt,
  /// including synchronously on a failed start, so [_isListening] already
  /// reflects success/failure by the time this returns.
  Future<bool> startListening() async {
    if (_isListening) return true;
    _isListening = true;
    notifyListeners();
    await _speechToText.startListening(
      onResult: (text) {
        inputController.text = text;
        inputController.selection = TextSelection.collapsed(
          offset: text.length,
        );
      },
      onDone: () {
        _isListening = false;
        notifyListeners();
      },
    );
    return _isListening;
  }

  Future<void> stopListening() => _speechToText.stopListening();

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

    // Checked before attempting the call so "you're offline" never has to
    // be inferred from a generic failure — see AiChatService.isOffline.
    final isOffline = _aiChatService.isOffline;
    final result = isOffline
        ? null
        : await _aiChatService.ask(
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
              text: isOffline ? offlineText : failureText,
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

  @override
  void dispose() {
    _speechToText.cancelListening();
    super.dispose();
  }
}
