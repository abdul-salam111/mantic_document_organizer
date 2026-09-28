import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Bridges Android/iOS "Share into Mantic" intents (a PDF emailed to you, a
/// photo shared from Gallery/WhatsApp, ...) to plain local file paths —
/// hides the receive_sharing_intent SDK's own [SharedMediaFile]/
/// [SharedMediaType] types from the rest of the app, same reasoning as
/// every other SDK-specific type at this app's core/ boundary. Only images
/// and generic files are considered — [SharedMediaType.video]/`.text`/
/// `.url` aren't documents this app organizes.
class ShareIntentService {
  List<String> _documentPaths(List<SharedMediaFile> media) => [
    for (final file in media)
      if (file.type == SharedMediaType.image ||
          file.type == SharedMediaType.file)
        file.path,
  ];

  /// Fires every time a share arrives while the app is already running —
  /// a cold-start share instead comes through [consumeInitialShare].
  Stream<List<String>> get sharedFilePaths => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(_documentPaths)
      .where((paths) => paths.isNotEmpty);

  /// The share (if any) that launched the app cold. Calls the SDK's own
  /// `reset()` afterward so the same share doesn't replay on a later warm
  /// start — safe to call even when nothing was shared.
  Future<List<String>> consumeInitialShare() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    await ReceiveSharingIntent.instance.reset();
    return _documentPaths(media);
  }
}
