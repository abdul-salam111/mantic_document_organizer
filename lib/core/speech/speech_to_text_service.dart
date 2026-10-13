import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// On-device speech-to-text for the AI assistant's input box — lets the
/// user speak a question instead of typing it, via the OS's own speech
/// recognizer (no network call, no API key). Always listens in English
/// (see [_localeId]) regardless of the app's display language; matching
/// the app's locale is a possible future enhancement, not something this
/// wraps today.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  static const String _localeId = 'en_US';

  bool _initialized = false;
  VoidCallback? _onDone;

  bool get isListening => _speech.isListening;

  /// One-time init, including the native mic/speech-recognition permission
  /// prompt. Safe to call repeatedly — a prior successful call is reused.
  /// Returns whether speech recognition is actually available (false if
  /// permission was denied or the device has no recognizer).
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = true;
    return _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _onDone?.call();
        }
      },
    );
  }

  /// Starts listening, calling [onResult] with the recognized text so far
  /// every time it updates — the caller decides what to do with it (e.g.
  /// fill a text field). [onDone] fires once listening stops, for any
  /// reason (silence timeout, [stopListening], [cancelListening], or a
  /// device error) — exactly once per [startListening] call, including
  /// when [initialize] itself fails, so the caller's "listening" UI state
  /// can always rely on it instead of also handling a separate failure
  /// path.
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required VoidCallback onDone,
  }) async {
    if (!await initialize()) {
      onDone();
      return;
    }
    _onDone = onDone;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: stt.SpeechListenOptions(
        localeId: _localeId,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> cancelListening() => _speech.cancel();

  void dispose() {
    if (_speech.isListening) _speech.cancel();
  }
}
