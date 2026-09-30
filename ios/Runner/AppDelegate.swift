import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: NativeOcrPlugin.key) {
      NativeOcrPlugin.register(with: registrar)
    }
  }
}

/// iOS OCR uses Vision, which is included with iOS and therefore needs no
/// an external dependency manager or third-party Swift package.
private final class NativeOcrPlugin: NSObject, FlutterPlugin {
  static let key = "NativeOcrPlugin"
  private let queue = DispatchQueue(label: "com.mantic.document.organizer.ocr")

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "mantic.document.organizer/ocr",
      binaryMessenger: registrar.messenger(),
    )
    let instance = NativeOcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText",
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String,
          !path.isEmpty else {
      result("")
      return
    }

    queue.async {
      let request = VNRecognizeTextRequest { request, error in
        let text: String
        if error == nil, let observations = request.results as? [VNRecognizedTextObservation] {
          text = Self.orderedText(observations)
        } else {
          text = ""
        }
        DispatchQueue.main.async { result(text) }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      request.recognitionLanguages = ["en-US"]

      do {
        try VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:]).perform([request])
      } catch {
        DispatchQueue.main.async { result("") }
      }
    }
  }

  private static func orderedText(_ observations: [VNRecognizedTextObservation]) -> String {
    let lines = observations.compactMap { observation -> (text: String, top: CGFloat, left: CGFloat, height: CGFloat)? in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      let box = observation.boundingBox
      return (candidate.string, 1 - box.maxY, box.minX, box.height)
    }
    guard !lines.isEmpty else { return "" }
    let heights = lines.map(\.height).sorted()
    let rowThreshold = heights[heights.count / 2] / 2
    return lines.sorted {
      abs($0.top - $1.top) < rowThreshold ? $0.left < $1.left : $0.top < $1.top
    }.map(\.text).joined(separator: "\n")
  }
}
