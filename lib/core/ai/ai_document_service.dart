import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../networks/network_manager/dio_helper.dart';

/// A best-effort suggestion for a newly-scanned document, produced by
/// sending its OCR'd text to an AI model. Every field is a *suggestion* —
/// [AddDocumentViewModel] pre-fills editable form fields with these, it
/// never saves a document on this alone.
class AiDocumentSuggestion {
  final String? title;

  /// Must match one of the category names passed into [AiDocumentService.analyze]
  /// (case-insensitively) — the caller resolves this back to a [CategoryItem];
  /// null (or an unresolvable name) just leaves the document uncategorized,
  /// same as not picking a category manually.
  final String? categoryName;

  /// Stored on the document for search only — never shown to the user, so
  /// the prompt asks for density/completeness over readability.
  final String description;

  /// Suggested search keywords/tags — loosely cleaned (trimmed, deduped)
  /// here; [AddDocumentViewModel] re-validates each one against the app's
  /// actual tag rules (allowed characters, length, count) before adding
  /// any, exactly like a manually-typed tag.
  final List<String> tags;
  final bool isExpirable;
  final DateTime? expiryDate;

  const AiDocumentSuggestion({
    this.title,
    this.categoryName,
    this.description = '',
    this.tags = const [],
    this.isExpirable = false,
    this.expiryDate,
  });
}

/// Organizes a document's OCR'd text into a title/category/summary/expiry
/// suggestion via an AI model, routed through OpenRouter
/// (https://openrouter.ai) so the underlying model is swappable via
/// [_model] without changing this integration. Reuses the existing
/// [DioHelper] rather than a separate HTTP client — its Bearer-auth
/// support and cached connectivity check (throwing [NoInternetException]
/// when offline) are exactly what this needs.
///
/// Every failure mode — offline, missing/invalid API key, a non-2xx
/// response, or a model reply that isn't valid/expected JSON — is
/// deliberately collapsed into a single `null` return. Callers can't tell
/// "offline" apart from "the model said something we couldn't parse," and
/// don't need to: either way, the right behavior is the same — skip AI
/// enrichment, keep the OCR text, let the user fill the form manually.
class AiDocumentService {
  final DioHelper _dioHelper;

  AiDocumentService(this._dioHelper);

  /// A fast/cheap model is plenty for this — it's summarizing a few
  /// hundred words of OCR text into a handful of fields, not reasoning at
  /// length. Verify this slug is still current at openrouter.ai/models if
  /// requests start failing; OpenRouter model slugs shift as providers
  /// release new versions.
  static const String _model = 'google/gemini-2.5-flash';

  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  String _systemPrompt(List<String> availableCategories) =>
      'You are a document-organizing assistant for a personal document '
      'manager app. You will be given raw OCR text extracted from a '
      'scanned document — expect OCR noise (misread characters, garbled '
      'lines, stray symbols, broken word spacing); read through it to the '
      'actual content rather than quoting it verbatim. Respond with ONLY a '
      'single JSON object (no prose, no markdown fences, no code block) '
      'with exactly these keys:\n\n'
      '"title": a short, natural, human-friendly title — 2 to 5 words. Do '
      'NOT copy the document\'s own printed heading. Lead with whatever a '
      'person would actually type to find this later: a person or company '
      'name if the document names one, then the document type. Never '
      'include an issuing country or authority\'s full formal name. '
      'Examples: OCR mentions "ISLAMIC REPUBLIC OF PAKISTAN NATIONAL '
      'IDENTITY CARD" + name "Abdul Salam" -> title "Abdul Salam ID Card". '
      'An invoice from "Acme Corp" numbered 4521 -> "Acme Corp Invoice '
      '#4521". A passport for "Jane Doe" -> "Jane Doe Passport".\n\n'
      '"category": pick the single best-fitting name, verbatim, from this '
      'exact list: [${availableCategories.join(', ')}] — or null if none '
      'fit.\n\n'
      '"description": a concise, factual, organized summary of the key '
      'information in the document (names, id/reference numbers, amounts, '
      'relevant dates — whatever is actually present). This is stored for '
      'search only and never shown to the user, so prefer completeness and '
      'exact values over polished prose. Plain text, no markdown.\n\n'
      '"tags": an array of 2 to 5 short lowercase search tags — document '
      'type, issuing organization/authority, and any other distinguishing '
      'term. Each tag must use only lowercase letters, numbers, and '
      'hyphens, with no spaces or punctuation (e.g. "id-card", '
      '"government", "pakistan", "insurance", "acme-corp"). No duplicates.'
      '\n\n'
      '"isExpirable": true only if the document clearly has a validity/'
      'expiry date (e.g. an ID, license, passport, insurance policy), '
      'false otherwise.\n\n'
      '"expiryDate": if isExpirable is true and an expiry date is present '
      'in the text, that date as "YYYY-MM-DD"; otherwise null. Do not '
      'confuse it with a date of birth or issue date.';

  /// Returns null on ANY failure — see class doc. Never throws.
  Future<AiDocumentSuggestion?> analyze({
    required String ocrText,
    required List<String> availableCategories,
  }) async {
    final text = ocrText.trim();
    if (text.isEmpty) return null;

    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_key_here') {
      return null;
    }

    try {
      final response = await _dioHelper.postApi(
        url: _endpoint,
        isAuthRequired: true,
        authToken: apiKey,
        requestBody: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt(availableCategories)},
            {'role': 'user', 'content': text},
          ],
          'response_format': {'type': 'json_object'},
          // Without an explicit cap, OpenRouter reserves the model's full
          // context window (tens of thousands of tokens) against the
          // account's credit balance before the call even starts, which
          // fails with a 402 on a low-balance/free-tier key. The response
          // here is always a small JSON object, so this is plenty.
          'max_tokens': 2000,
        },
      );

      final choices = (response as Map)['choices'] as List;
      final message = (choices.first as Map)['message'] as Map;
      final content = message['content'] as String;
      final parsed = jsonDecode(content) as Map;

      return AiDocumentSuggestion(
        title: _cleanString(parsed['title']),
        categoryName: _cleanString(parsed['category']),
        description: _cleanString(parsed['description']) ?? '',
        tags: _parseTags(parsed['tags']),
        isExpirable: parsed['isExpirable'] == true,
        expiryDate: parsed['isExpirable'] == true
            ? _parseIsoDate(parsed['expiryDate'])
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  String? _cleanString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseIsoDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Only trims/dedupes here — [AddDocumentViewModel] re-validates each tag
  /// against the app's actual rules (allowed characters, length, count)
  /// before adding it, same as a manually-typed tag.
  List<String> _parseTags(Object? value) {
    if (value is! List) return const [];
    final seen = <String>{};
    final tags = <String>[];
    for (final item in value) {
      if (item is! String) continue;
      final trimmed = item.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      tags.add(trimmed);
    }
    return tags;
  }
}
