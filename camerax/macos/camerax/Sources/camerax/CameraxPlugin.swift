import Cocoa
import FlutterMacOS

public class CameraxPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "camerax", binaryMessenger: registrar.messenger)
    let instance = CameraxPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "processCaptureImage":
      guard let args = call.arguments as? [String: Any],
        let input = args["inputPath"] as? String,
        let output = args["outputPath"] as? String,
        let ratio = args["aspectRatio"] as? Double
      else {
        result(
          FlutterError(code: "bad_args", message: "inputPath, outputPath, aspectRatio", details: nil))
        return
      }
      let q = (args["quality"] as? Int).map { Double($0) } ?? 95.0
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try cameraxProcessCaptureImage(
            inputPath: input, outputPath: output, aspectRatio: ratio, quality: q)
          DispatchQueue.main.async { result(true) }
        } catch {
          DispatchQueue.main.async { result(false) }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
