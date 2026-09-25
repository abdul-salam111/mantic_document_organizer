import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../features/home/home_exports.dart' show DocumentItem;
import '../networks/network_manager/dio_helper.dart';

/// One prior question/answer pair, folded into the prompt so follow-up
/// questions ("what about last month's water bill") can use context from
/// earlier in the conversation. The caller ([AiAssistantViewModel]) is
/// responsible for capping how many of these it passes in.
class ChatExchange {
  final String question;
  final String answer;

  const ChatExchange({required this.question, required this.answer});
}

/// A best-effort answer to a question about the user's documents.
class AiChatAnswer {
  final String answer;

  /// `DocumentItem.id` values the answer is based on — empty if nothing in
  /// the user's documents matched the question.
  final List<String> documentIds;

  const AiChatAnswer({required this.answer, this.documentIds = const []});
}

/// Answers natural-language questions about the user's documents by
/// sending a compact catalog of them (title/category/tags/description/
/// expiry — never raw OCR text) to an AI model via OpenRouter, alongside
/// the question and recent conversation history. Same integration shape as
/// [AiDocumentService]: reuses [DioHelper] (Bearer auth, offline detection
/// via its cached connectivity check), and collapses every failure mode —
/// offline, missing/invalid API key, a non-2xx response, a reply that
/// isn't valid/expected JSON — into a single `null` return. Callers can't
/// tell these apart and don't need to: the right behavior is always the
/// same, show a friendly "couldn't answer that" message, never crash.
class AiChatService {
  final DioHelper _dioHelper;

  AiChatService(this._dioHelper);

  /// Same fast/cheap model as [AiDocumentService] — a short, direct answer
  /// doesn't need a larger/slower model. Verify this slug is still current
  /// at openrouter.ai/models if requests start failing.
  static const String _model = 'google/gemini-2.5-flash';

  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  /// How much of a document's OCR text to fall back to when its AI-written
  /// [DocumentItem.description] is empty (added before AI enrichment
  /// existed, added while offline, or the enrichment call itself failed) —
  /// enough to be useful without ballooning the request for a document
  /// that otherwise contributes almost nothing to the catalog.
  static const int _ocrFallbackChars = 500;

  String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

  String _systemPrompt(String todayIso, List<Map<String, dynamic>> catalog) =>
      'You are a helpful assistant inside a personal document manager app. '
      'Today\'s date is $todayIso; resolve relative dates ("last month", '
      '"this year") against it.\n\n'
      'Answer ONLY from the document catalog below — never invent a '
      'document, a date, or an amount that isn\'t actually there. If '
      'nothing in the catalog answers the question, say so plainly and '
      'honestly instead of guessing.\n\n'
      'Respond with ONLY a single JSON object (no prose, no markdown '
      'fences, no code block) with exactly these keys:\n\n'
      '"answer": a short, direct, conversational answer — a sentence or '
      'two, not a report. Include the concrete value asked for (an amount, '
      'a date, a name) when it\'s available.\n\n'
      '"documentIds": an array of the "id" values (from the catalog below) '
      'that this answer is based on — an empty array if none apply. Only '
      'include ids that are actually relevant, never pad this list.\n\n'
      'Document catalog (JSON array):\n${jsonEncode(catalog)}';

  Map<String, dynamic> _documentJson(DocumentItem document) {
    final summary = document.description.trim().isNotEmpty
        ? document.description.trim()
        : document.ocrText.trim();
    final description = summary.length > _ocrFallbackChars
        ? summary.substring(0, _ocrFallbackChars)
        : summary;
    return {
      'id': document.id,
      'title': document.title,
      'category': document.category,
      'tags': document.tags,
      'description': description,
      'isExpirable': document.isExpirable,
      'expiryDate': document.expiryDate == null
          ? null
          : _isoDate(document.expiryDate!),
      'createdAt': _isoDate(document.createdAt),
    };
  }

  /// Returns null on ANY failure — see class doc. Never throws.
  Future<AiChatAnswer?> ask({
    required String question,
    required List<DocumentItem> documents,
    required List<ChatExchange> history,
  }) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) return null;

    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_key_here') {
      return null;
    }

    try {
      final catalog = documents.map(_documentJson).toList();
      final systemPrompt = _systemPrompt(_isoDate(DateTime.now()), catalog);

      final response = await _dioHelper.postApi(
        url: _endpoint,
        isAuthRequired: true,
        authToken: apiKey,
        requestBody: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            for (final exchange in history) ...[
              {'role': 'user', 'content': exchange.question},
              {'role': 'assistant', 'content': exchange.answer},
            ],
            {'role': 'user', 'content': trimmedQuestion},
          ],
          'response_format': {'type': 'json_object'},
          // A chat answer is a sentence or two, not a report — keep this
          // capped the same way AiDocumentService does, so a low-credit
          // key can't hit the same 402 an uncapped request did before.
          'max_tokens': 800,
        },
      );

      final choices = (response as Map)['choices'] as List;
      final message = (choices.first as Map)['message'] as Map;
      final content = message['content'] as String;
      final parsed = jsonDecode(content) as Map;

      final answer = parsed['answer'];
      if (answer is! String || answer.trim().isEmpty) return null;

      return AiChatAnswer(
        answer: answer.trim(),
        documentIds: _parseDocumentIds(parsed['documentIds']),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _parseDocumentIds(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
}
