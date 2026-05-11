package cn.hwato.camerax

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class CameraxPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val executor = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
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

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
