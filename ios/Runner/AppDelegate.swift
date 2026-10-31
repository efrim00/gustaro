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

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GustaroNative") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "gustaro/native", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "recognizeText":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "Expected a file path", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let text = Self.recognizeText(atPath: path)
          DispatchQueue.main.async { result(text) }
        }
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// On-device text recognition with Apple Vision. Nothing leaves the phone.
  /// Returns an empty string when no text is found.
  private static func recognizeText(atPath path: String) -> String {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      return ""
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false  // Wine names are not dictionary words.
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    request.recognitionLanguages = ["ro-RO", "en-US", "fr-FR", "ru-RU"].filter {
      supported.contains($0)
    }
    let handler = VNImageRequestHandler(
      cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    do {
      try handler.perform([request])
    } catch {
      return ""
    }
    return (request.results ?? [])
      .compactMap { $0.topCandidates(1).first?.string }
      .joined(separator: "\n")
  }
}

extension CGImagePropertyOrientation {
  fileprivate init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
