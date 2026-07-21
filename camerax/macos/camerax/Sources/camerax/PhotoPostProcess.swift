import CoreGraphics
import CoreImage
import Foundation
import ImageIO

enum CameraxPhotoError: Error {
  case loadFailed
  case renderFailed
  case encodeFailed
}

/// EXIF 方向校正后按宽高比（宽/高）中心裁剪，输出 JPEG。
func cameraxProcessCaptureImage(
  inputPath: String,
  outputPath: String,
  aspectRatio: Double,
  quality: Double,
) throws {
  guard aspectRatio > 0, aspectRatio.isFinite else {
    throw CameraxPhotoError.loadFailed
  }
  let url = URL(fileURLWithPath: inputPath) as CFURL
  guard let source = CGImageSourceCreateWithURL(url, nil) else {
    throw CameraxPhotoError.loadFailed
  }
  guard let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    throw CameraxPhotoError.loadFailed
  }
  var exifOrientation: Int32 = 1
  if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
    let o = props[kCGImagePropertyOrientation as String] as? Int32
  {
    exifOrientation = o
  } else if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any],
    let n = props[kCGImagePropertyOrientation] as? NSNumber
  {
    exifOrientation = n.int32Value
  }

  let ci = CIImage(cgImage: cg)
  let oriented = ci.oriented(forExifOrientation: exifOrientation)
  let context = CIContext(options: [.useSoftwareRenderer: false])

  let extent = oriented.extent
  let w = Int(extent.width)
  let h = Int(extent.height)
  guard w > 0, h > 0 else { throw CameraxPhotoError.renderFailed }

  let sourceAspect = Double(w) / Double(h)
  if abs(sourceAspect - aspectRatio) < 0.01 {
    guard let upCg = context.createCGImage(oriented, from: extent) else {
      throw CameraxPhotoError.renderFailed
    }
    try writeJpeg(cgImage: upCg, outputPath: outputPath, quality: quality)
    return
  }

  var cropW = w
  var cropH = h
  if sourceAspect > aspectRatio {
    cropW = Int((Double(h) * aspectRatio).rounded())
  } else {
    cropH = Int((Double(w) / aspectRatio).rounded())
  }
  cropW = max(1, min(cropW, w))
  cropH = max(1, min(cropH, h))
  let left = extent.origin.x + CGFloat(w - cropW) / 2
  let top = extent.origin.y + CGFloat(h - cropH) / 2
  let rect = CGRect(x: left, y: top, width: CGFloat(cropW), height: CGFloat(cropH))
  let cropped = oriented.cropped(to: rect)
  guard let outCg = context.createCGImage(cropped, from: cropped.extent) else {
    throw CameraxPhotoError.renderFailed
  }
  try writeJpeg(cgImage: outCg, outputPath: outputPath, quality: quality)
}

private func writeJpeg(cgImage: CGImage, outputPath: String, quality: Double) throws {
  let q = max(0.01, min(1.0, quality / 100.0))
  let destUrl = URL(fileURLWithPath: outputPath) as CFURL
  guard
    let dest = CGImageDestinationCreateWithURL(
      destUrl, "public.jpeg" as CFString, 1, nil)
  else {
    throw CameraxPhotoError.encodeFailed
  }
  let opts: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: q]
  CGImageDestinationAddImage(dest, cgImage, opts as CFDictionary)
  if !CGImageDestinationFinalize(dest) {
    throw CameraxPhotoError.encodeFailed
  }
}
