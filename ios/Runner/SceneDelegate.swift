import Flutter
import UIKit
import receive_sharing_intent

/// Adopts `UISceneDelegate`, required by Flutter's newer scene-based
/// lifecycle (see UIApplicationSceneManifest in Info.plist). The override
/// here is what actually lets shared files reach `ShareIntentService` on
/// iOS: `google_sign_in`/`flutter_web_auth_2` also compete for incoming-URL
/// callbacks on this same scene hook, so the plugin's handler is given
/// first refusal before falling back to the default behavior.
class SceneDelegate: FlutterSceneDelegate {
  // Cold start: the share extension's hand-off URL (if any) arrives via
  // connectionOptions rather than launchOptions under the scene lifecycle.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    _ = ReceiveSharingIntentPlugin.instance.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  // Warm start: the app is already running when a share comes in.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if ReceiveSharingIntentPlugin.instance.scene(scene, openURLContexts: URLContexts) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
