import Flutter
import UIKit

public class CameraxPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "camerax", binaryMessenger: registrar.messenger())
    let instance = CameraxPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

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

    case "mergeCaptureWithOverlay":
      guard let args = call.arguments as? [String: Any],
        let input = args["inputPath"] as? String,
        let output = args["outputPath"] as? String
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "inputPath, outputPath",
            details: nil))
        return
      }
      let overlayBytes = (args["overlayBytes"] as? FlutterStandardTypedData)?.data
      let overlayPath = args["overlayPath"] as? String
      if overlayBytes == nil && overlayPath == nil {
        result(
          FlutterError(
            code: "bad_args",
            message: "overlayBytes or overlayPath is required",
            details: nil))
        return
      }
      let q = (args["quality"] as? Int).map { Double($0) } ?? 95.0
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          if let bytes = overlayBytes {
            try cameraxMergeCaptureWithOverlayData(
              inputPath: input, overlayData: bytes, outputPath: output, quality: q)
          } else {
            try cameraxMergeCaptureWithOverlay(
              inputPath: input, overlayPath: overlayPath!, outputPath: output, quality: q)
          }
          DispatchQueue.main.async { result(true) }
        } catch {
          DispatchQueue.main.async { result(false) }
        }
      }

    case "mergeVideoWithOverlay":
      guard let args = call.arguments as? [String: Any],
        let input = args["inputPath"] as? String,
        let output = args["outputPath"] as? String
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "inputPath, outputPath",
            details: nil))
        return
      }
      let overlayBytes = (args["overlayBytes"] as? FlutterStandardTypedData)?.data
      let overlayPath = args["overlayPath"] as? String
      let keyframes = cameraxParseOverlayKeyframes(args["overlayKeyframes"])
      if overlayBytes == nil && overlayPath == nil {
        result(
          FlutterError(
            code: "bad_args",
            message: "overlayBytes or overlayPath is required",
            details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          if let bytes = overlayBytes {
            try cameraxMergeVideoWithOverlayData(
              inputPath: input,
              overlayData: bytes,
              outputPath: output,
              keyframes: keyframes
            )
          } else {
            let data = try Data(contentsOf: URL(fileURLWithPath: overlayPath!))
            try cameraxMergeVideoWithOverlayData(
              inputPath: input,
              overlayData: data,
              outputPath: output,
              keyframes: keyframes
            )
          }
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

private func cameraxParseOverlayKeyframes(_ raw: Any?) -> [CameraxOverlayKeyframe] {
  guard let list = raw as? [[String: Any]] else {
    return []
  }
  var keyframes: [CameraxOverlayKeyframe] = []
  for entry in list {
    guard let offsetMs = (entry["offsetMs"] as? NSNumber)?.int64Value,
      let path = entry["path"] as? String,
      !path.isEmpty,
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
      let image = UIImage(data: data)
    else {
      continue
    }
    keyframes.append(CameraxOverlayKeyframe(offsetMs: offsetMs, image: image))
  }
  return keyframes.sorted { $0.offsetMs < $1.offsetMs }
}
