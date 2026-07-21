import AVFoundation
import UIKit

struct CameraxOverlayKeyframe {
  let offsetMs: Int64
  let image: UIImage
}

func cameraxMergeVideoWithOverlayData(
  inputPath: String,
  overlayData: Data,
  outputPath: String,
  keyframes: [CameraxOverlayKeyframe] = []
) throws {
  guard let fallbackOverlay = UIImage(data: overlayData) else {
    throw CameraxPhotoError.loadFailed
  }
  try cameraxMergeVideoWithOverlayImages(
    inputPath: inputPath,
    fallbackOverlay: fallbackOverlay,
    keyframes: keyframes,
    outputPath: outputPath
  )
}

func cameraxMergeVideoWithOverlayImages(
  inputPath: String,
  fallbackOverlay: UIImage,
  keyframes: [CameraxOverlayKeyframe],
  outputPath: String
) throws {
  let inputUrl = URL(fileURLWithPath: inputPath)
  let asset = AVURLAsset(url: inputUrl)
  guard let videoTrack = asset.tracks(withMediaType: .video).first else {
    throw CameraxPhotoError.loadFailed
  }

  let composition = AVMutableComposition()
  guard
    let compositionVideoTrack = composition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )
  else {
    throw CameraxPhotoError.renderFailed
  }

  let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
  try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

  if let audioTrack = asset.tracks(withMediaType: .audio).first,
    let compositionAudioTrack = composition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )
  {
    try? compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
  }

  let transform = videoTrack.preferredTransform
  let naturalSize = videoTrack.naturalSize
  let transformedSize = naturalSize.applying(transform)
  let renderWidth = abs(transformedSize.width)
  let renderHeight = abs(transformedSize.height)
  guard renderWidth > 0, renderHeight > 0 else {
    throw CameraxPhotoError.renderFailed
  }

  let renderSize = CGSize(width: renderWidth, height: renderHeight)
  let orderedKeyframes = keyframes.sorted { $0.offsetMs < $1.offsetMs }
  let overlayFrames = orderedKeyframes.isEmpty
    ? [CameraxOverlayKeyframe(offsetMs: 0, image: fallbackOverlay)]
    : orderedKeyframes

  let parentLayer = CALayer()
  let videoLayer = CALayer()
  let overlayLayer = CALayer()
  parentLayer.frame = CGRect(origin: .zero, size: renderSize)
  videoLayer.frame = parentLayer.frame
  overlayLayer.frame = parentLayer.frame
  overlayLayer.contentsGravity = .resize
  parentLayer.addSublayer(videoLayer)
  parentLayer.addSublayer(overlayLayer)

  let durationSeconds = max(asset.duration.seconds, 0.001)
  if overlayFrames.count == 1,
    let overlayCG = cameraxResizeImage(overlayFrames[0].image, to: renderSize).cgImage
  {
    overlayLayer.contents = overlayCG
  } else {
    var values: [CGImage] = []
    var keyTimes: [NSNumber] = []
    for frame in overlayFrames {
      guard let cgImage = cameraxResizeImage(frame.image, to: renderSize).cgImage else {
        continue
      }
      values.append(cgImage)
      let seconds = max(0, Double(frame.offsetMs) / 1000.0)
      keyTimes.append(NSNumber(value: min(1.0, seconds / durationSeconds)))
    }
    if values.isEmpty {
      throw CameraxPhotoError.renderFailed
    }
    if keyTimes.first?.doubleValue != 0 {
      values.insert(values[0], at: 0)
      keyTimes.insert(0, at: 0)
    }
    if keyTimes.last?.doubleValue != 1 {
      values.append(values[values.count - 1])
      keyTimes.append(1)
    }
    let animation = CAKeyframeAnimation(keyPath: "contents")
    animation.values = values
    animation.keyTimes = keyTimes
    animation.duration = durationSeconds
    animation.beginTime = AVCoreAnimationBeginTimeAtZero
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    overlayLayer.add(animation, forKey: "overlayContents")
    overlayLayer.contents = values[values.count - 1]
  }

  let videoComposition = AVMutableVideoComposition()
  videoComposition.renderSize = renderSize
  videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
  videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: parentLayer
  )

  let instruction = AVMutableVideoCompositionInstruction()
  instruction.timeRange = timeRange
  let layerInstruction = AVMutableVideoCompositionLayerInstruction(
    assetTrack: compositionVideoTrack
  )
  layerInstruction.setTransform(transform, at: .zero)
  instruction.layerInstructions = [layerInstruction]
  videoComposition.instructions = [instruction]

  guard
    let exportSession = AVAssetExportSession(
      asset: composition,
      presetName: AVAssetExportPresetHighestQuality
    )
  else {
    throw CameraxPhotoError.renderFailed
  }

  let outputUrl = URL(fileURLWithPath: outputPath)
  try? FileManager.default.removeItem(at: outputUrl)
  exportSession.outputURL = outputUrl
  exportSession.outputFileType = .mp4
  exportSession.videoComposition = videoComposition

  let semaphore = DispatchSemaphore(value: 0)
  var exportError: Error?
  exportSession.exportAsynchronously {
    if exportSession.status != .completed {
      exportError = exportSession.error ?? CameraxPhotoError.encodeFailed
    }
    semaphore.signal()
  }
  semaphore.wait()
  if let exportError {
    throw exportError
  }
}

func cameraxRemoveVideoWatermark(inputPath: String, outputPath: String) throws {
  let inputUrl = URL(fileURLWithPath: inputPath)
  let asset = AVURLAsset(url: inputUrl)
  guard asset.tracks(withMediaType: .video).first != nil else {
    throw CameraxPhotoError.loadFailed
  }

  let generator = AVAssetImageGenerator(asset: asset)
  generator.appliesPreferredTrackTransform = true
  let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
  let frame = UIImage(cgImage: cgImage)
  let healed = cameraxHealBottomWatermark(frame)
  let overlay = cameraxBuildHealPatchOverlay(healed: healed, size: frame.size)
  try cameraxMergeVideoWithOverlayImages(
    inputPath: inputPath,
    fallbackOverlay: overlay,
    keyframes: [],
    outputPath: outputPath
  )
}

private func cameraxHealBottomWatermark(_ image: UIImage) -> UIImage {
  let width = Int(image.size.width)
  let height = Int(image.size.height)
  guard width > 0, height > 0 else { return image }

  let format = UIGraphicsImageRendererFormat.default()
  format.scale = 1
  let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
  return renderer.image { ctx in
    image.draw(in: CGRect(origin: .zero, size: image.size))
    let cropHeight = max(1, Int(Double(height) * 0.22))
    let cropWidth = max(1, Int(Double(width) * 0.72))
    let sampleY = max(
      0,
      min(height - 1, height - cropHeight - Int(Double(height) * 0.04))
    )
    guard let cg = image.cgImage else { return }
    for y in sampleY..<height {
      if let row = cg.cropping(
        to: CGRect(x: 0, y: sampleY, width: cropWidth, height: 1)
      ) {
        ctx.cgContext.draw(
          row,
          in: CGRect(x: 0, y: y, width: cropWidth, height: 1)
        )
      }
    }
  }
}

private func cameraxBuildHealPatchOverlay(healed: UIImage, size: CGSize) -> UIImage {
  let width = Int(size.width)
  let height = Int(size.height)
  let cropHeight = max(1, Int(Double(height) * 0.22))
  let cropWidth = max(1, Int(Double(width) * 0.72))
  let top = max(
    0,
    min(height - 1, height - cropHeight - Int(Double(height) * 0.04))
  )

  let format = UIGraphicsImageRendererFormat.default()
  format.scale = 1
  format.opaque = false
  let renderer = UIGraphicsImageRenderer(size: size, format: format)
  return renderer.image { _ in
    let patchRect = CGRect(
      x: 0,
      y: CGFloat(top),
      width: CGFloat(cropWidth),
      height: CGFloat(height - top)
    )
    healed.draw(in: patchRect, blendMode: .normal, alpha: 1)
  }
}

private func cameraxResizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
  let format = UIGraphicsImageRendererFormat.default()
  format.scale = 1
  let renderer = UIGraphicsImageRenderer(size: size, format: format)
  return renderer.image { _ in
    image.draw(in: CGRect(origin: .zero, size: size))
  }
}
