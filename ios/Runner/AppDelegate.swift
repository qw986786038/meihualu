import Flutter
import UIKit

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
        MergeOverlayIos.register(registry: engineBridge.pluginRegistry)
        AppPathsIos.register(registry: engineBridge.pluginRegistry)
    }
}

private enum AppPathsIos {
    private static let channelName = "cn.hwato.watermark_camera/app_paths"
    private static let originalStoreDir = "watermark_originals"

    static func register(registry: FlutterPluginRegistry) {
        let registrar = registry.registrar(forPlugin: "WatermarkAppPathsPlugin")
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            guard call.method == "getOriginalStoreDir" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else {
                result(FlutterError(code: "NO_DIR", message: "documents unavailable", details: nil))
                return
            }
            let dir = documents.appendingPathComponent(originalStoreDir, isDirectory: true)
            do {
                try FileManager.default.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true
                )
                result(dir.path)
            } catch {
                result(FlutterError(code: "NO_DIR", message: error.localizedDescription, details: nil))
            }
        }
    }
}

private enum MergeOverlayIos {
    private static let channelName = "cn.hwato.watermark_camera/merge_overlay"

    static func register(registry: FlutterPluginRegistry) {
        let registrar = registry.registrar(forPlugin: "WatermarkMergeOverlayPlugin")

        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            guard call.method == "mergeOverlayJpeg" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard
                let args = call.arguments as? [String: Any],
                let basePath = args["basePath"] as? String,
                basePath.isEmpty == false
            else {
                result(FlutterError(code: "BAD_ARGS", message: "missing basePath", details: nil))
                return
            }

            let qualityInt = args["jpegQuality"] as? Int ?? 88
            let clampedQ = Swift.min(100, Swift.max(1, qualityInt))
            let jpegQ = CGFloat(clampedQ) / 100.0

            let maxEdgeArg = args["mergeMaxLongEdge"] as? Int ?? 0
            let maxLongPx = CGFloat(Swift.max(0, maxEdgeArg))

            let overlayFlutterData = args["overlayPngBytes"] as? FlutterStandardTypedData
            let pngData = overlayFlutterData?.data
            guard let pngData, pngData.isEmpty == false else {
                result(FlutterError(code: "BAD_ARGS", message: "missing overlay", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let outPath = try mergeOverlayToTempJpegIos(
                        basePath: basePath,
                        overlayPngData: pngData,
                        jpegQuality: jpegQ,
                        maxLongEdgePx: maxLongPx
                    )
                    DispatchQueue.main.async { result(outPath) }
                } catch {
                    DispatchQueue.main.async {
                        let message = (error as NSError).localizedDescription
                        result(FlutterError(code: "MERGE_FAIL", message: message, details: nil))
                    }
                }
            }
        }
    }
}

private extension UIImage {
    var pixelDimensions: CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }
}

/// 将 UIImage 的 `imageOrientation` 画进像素，再合并，避免竖拍成片与预览方向不一致。
private func normalizedUprightUIImage(_ image: UIImage) -> UIImage {
    guard image.imageOrientation != .up else { return image }
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: image.size))
    }
}

private func mergeOverlayToTempJpegIos(
    basePath: String,
    overlayPngData: Data,
    jpegQuality: CGFloat,
    maxLongEdgePx: CGFloat
) throws -> String {
    guard let baseRaw = UIImage(contentsOfFile: basePath) else {
        throw NSError(domain: "WatermarkMerge", code: -10, userInfo: [NSLocalizedDescriptionKey: "cannot load base"])
    }
    let baseImage = normalizedUprightUIImage(baseRaw)

    guard let overlay = UIImage(data: overlayPngData) else {
        throw NSError(domain: "WatermarkMerge", code: -11, userInfo: [NSLocalizedDescriptionKey: "cannot decode overlay"])
    }

    var targetW = baseImage.pixelDimensions.width
    var targetH = baseImage.pixelDimensions.height

    if maxLongEdgePx > 0 {
        let longEdge = Swift.max(targetW, targetH)
        if longEdge > maxLongEdgePx {
            let ratio = maxLongEdgePx / longEdge
            targetW *= ratio
            targetH *= ratio
        }
    }

    let bw = targetW
    let bh = targetH
    let ow = overlay.pixelDimensions.width
    let oh = overlay.pixelDimensions.height
    guard ow >= 1, oh >= 1 else {
        throw NSError(domain: "WatermarkMerge", code: -12, userInfo: [NSLocalizedDescriptionKey: "overlay too small"])
    }

    let fitScale = Swift.min(bw / ow, bh / oh)
    let drawW = ow * fitScale
    let drawH = oh * fitScale
    let dx = (bw - drawW) / 2
    let dy = (bh - drawH) / 2

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    let canvasSize = CGSize(width: bw, height: bh)
    let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
    let merged = renderer.image { _ in
        baseImage.draw(in: CGRect(origin: .zero, size: canvasSize))
        overlay.draw(
            in: CGRect(x: dx, y: dy, width: drawW, height: drawH),
            blendMode: .normal,
            alpha: 1
        )
    }

    guard let jpeg = merged.jpegData(compressionQuality: jpegQuality) else {
        throw NSError(domain: "WatermarkMerge", code: -13, userInfo: [NSLocalizedDescriptionKey: "jpeg encode"])
    }

    let name = "wm_merge_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(name)
    try jpeg.write(to: url, options: .atomic)

    return url.path
}
