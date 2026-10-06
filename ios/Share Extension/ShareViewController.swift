import receive_sharing_intent

/// The iOS counterpart to Android's share-sheet intent-filters
/// (AndroidManifest.xml) — this is what makes Dockitly appear in iOS's
/// native share sheet for images and files/PDFs. No UI of its own:
/// `shouldAutoRedirect` hands off straight to the host app, which then
/// picks the shared files up through `ShareIntentService`
/// (lib/core/sharing/share_intent_service.dart), same as Android.
class ShareViewController: RSIShareViewController {
  override func shouldAutoRedirect() -> Bool {
    true
  }
}
