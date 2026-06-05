package cn.hwato.camerax

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class CameraxPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val executor = Executors.newSingleThreadExecutor()
    private var liveRecorder: LiveWatermarkVideoRecorder? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "camerax")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" ->
                result.success("Android ${android.os.Build.VERSION.RELEASE}")

            "processCaptureImage" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val input = args["inputPath"] as? String
                val output = args["outputPath"] as? String
                val ratio = (args["aspectRatio"] as? Number)?.toDouble()
                val quality = (args["quality"] as? Number)?.toInt() ?: 95
                if (input == null || output == null || ratio == null) {
                    result.error("bad_args", "inputPath, outputPath, aspectRatio required", null)
                    return
                }
                executor.execute {
                    val ok = try {
                        PhotoPostProcessor.processCaptureImage(input, output, ratio, quality)
                    } catch (e: Exception) {
                        false
                    }
                    result.success(ok)
                }
            }
            "mergeCaptureWithOverlay" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val input = args["inputPath"] as? String
                val overlayBytes = args["overlayBytes"] as? ByteArray
                val overlay = args["overlayPath"] as? String
                val output = args["outputPath"] as? String
                val quality = (args["quality"] as? Number)?.toInt() ?: 95
                if (input == null || output == null || (overlayBytes == null && overlay == null)) {
                    result.error("bad_args", "inputPath, outputPath and overlayBytes/overlayPath required", null)
                    return
                }
                executor.execute {
                    val ok = try {
                        if (overlayBytes != null) {
                            PhotoPostProcessor.mergeCaptureWithOverlayBytes(input, overlayBytes, output, quality)
                        } else {
                            PhotoPostProcessor.mergeCaptureWithOverlay(input, overlay!!, output, quality)
                        }
                    } catch (e: Exception) {
                        false
                    }
                    result.success(ok)
                }
            }
            "startLiveWatermarkVideoRecording" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val output = args["outputPath"] as? String
                val overlayBytes = args["overlayBytes"] as? ByteArray
                val captureAspectRatio =
                    (args["captureAspectRatio"] as? Number)?.toFloat() ?: 0f
                if (output == null) {
                    result.error("bad_args", "outputPath required", null)
                    return
                }
                executor.execute {
                    liveRecorder?.stop()
                    liveRecorder = LiveWatermarkVideoRecorder()
                    val ok = liveRecorder?.start(
                        output,
                        overlayBytes,
                        captureAspectRatio,
                    ) == true
                    if (!ok) {
                        liveRecorder = null
                    }
                    result.success(ok)
                }
            }
            "updateLiveWatermarkOverlay" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val overlayBytes = args["overlayBytes"] as? ByteArray
                executor.execute {
                    liveRecorder?.updateOverlay(overlayBytes)
                    result.success(true)
                }
            }
            "pushLiveWatermarkVideoFrame" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val nv21 = args["nv21"] as? ByteArray
                val width = (args["width"] as? Number)?.toInt()
                val height = (args["height"] as? Number)?.toInt()
                val rotation = (args["rotation"] as? Number)?.toInt() ?: 0
                val captureTimeUs = (args["captureTimeUs"] as? Number)?.toLong() ?: 0L
                if (nv21 == null || width == null || height == null) {
                    result.error("bad_args", "nv21, width, height required", null)
                    return
                }
                executor.execute {
                    val ok = liveRecorder?.encodeNv21Frame(
                        nv21,
                        width,
                        height,
                        rotation,
                        captureTimeUs,
                    ) == true
                    result.success(ok)
                }
            }
            "stopLiveWatermarkVideoRecording" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                val recordingEndUs = (args?.get("recordingEndUs") as? Number)?.toLong() ?: 0L
                executor.execute {
                    val ok = liveRecorder?.stop(recordingEndUs) == true
                    liveRecorder = null
                    result.success(ok)
                }
            }
            "mergeVideoWithOverlay" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return
                }
                val input = args["inputPath"] as? String
                val overlayBytes = args["overlayBytes"] as? ByteArray
                val overlayPath = args["overlayPath"] as? String
                val output = args["outputPath"] as? String
                val keyframePaths = parseOverlayKeyframes(args["overlayKeyframes"])
                if (input == null || output == null || (overlayBytes == null && overlayPath == null)) {
                    result.error(
                        "bad_args",
                        "inputPath, outputPath and overlayBytes/overlayPath required",
                        null,
                    )
                    return
                }
                executor.execute {
                    val ok = try {
                        when {
                            overlayBytes != null -> {
                                VideoPostProcessor.mergeVideoWithOverlayBytes(
                                    appContext,
                                    input,
                                    overlayBytes,
                                    output,
                                    keyframePaths,
                                )
                            }
                            else -> {
                                VideoPostProcessor.mergeVideoWithOverlayPath(
                                    appContext,
                                    input,
                                    overlayPath!!,
                                    output,
                                    keyframePaths,
                                )
                            }
                        }
                    } catch (e: Exception) {
                        false
                    }
                    result.success(ok)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        liveRecorder?.stop()
        liveRecorder = null
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    private fun parseOverlayKeyframes(raw: Any?): List<Pair<Long, String>> {
        @Suppress("UNCHECKED_CAST")
        val list = raw as? List<Map<String, Any?>> ?: return emptyList()
        val keyframes = mutableListOf<Pair<Long, String>>()
        for (entry in list) {
            val offsetMs = (entry["offsetMs"] as? Number)?.toLong() ?: continue
            val path = entry["path"] as? String ?: continue
            if (path.isNotEmpty()) {
                keyframes.add(offsetMs to path)
            }
        }
        return keyframes.sortedBy { it.first }
    }
}
