package com.palsmon.mediarecord.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.os.Handler
import android.os.Looper
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val CHANNEL = "cn.hwato.watermark_camera/merge_overlay"
        private const val APP_PATHS_CHANNEL = "cn.hwato.watermark_camera/app_paths"
        private const val ORIGINAL_STORE_DIR = "watermark_originals"
        private val backgroundExecutor = Executors.newCachedThreadPool()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_PATHS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getOriginalStoreDir") {
                    val dir = File(applicationContext.filesDir, ORIGINAL_STORE_DIR)
                    if (!dir.exists()) {
                        dir.mkdirs()
                    }
                    result.success(dir.absolutePath)
                    return@setMethodCallHandler
                }
                result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "mergeOverlayJpeg") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val basePath = call.argument<String>("basePath")
            val overlayBytes = call.argument<ByteArray>("overlayPngBytes")
            val jpegQualityArg = call.argument<Int>("jpegQuality") ?: 88
            val maxLongEdgeArg = call.argument<Int>("mergeMaxLongEdge") ?: 0

            if (basePath.isNullOrEmpty() || overlayBytes == null) {
                result.error("BAD_ARGS", "basePath / overlay required", null)
                return@setMethodCallHandler
            }

            val jpegQuality = jpegQualityArg.coerceIn(1, 100)
            val maxLongEdge = maxLongEdgeArg.coerceAtLeast(0)
            val cacheDir = applicationContext.cacheDir

            backgroundExecutor.execute {
                try {
                    val outPath = mergeOverlayToTempJpeg(
                        cacheDir = cacheDir,
                        basePath = basePath,
                        overlayPng = overlayBytes,
                        jpegQuality = jpegQuality,
                        maxLongEdge = maxLongEdge,
                    )
                    mainHandler.post { result.success(outPath) }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("MERGE_FAIL", e.message, null)
                    }
                }
            }
        }
    }
}

private fun mergeOverlayToTempJpeg(
    cacheDir: File,
    basePath: String,
    overlayPng: ByteArray,
    jpegQuality: Int,
    maxLongEdge: Int,
): String {
    val opts = BitmapFactory.Options().apply {
        inPreferredConfig = Bitmap.Config.ARGB_8888
    }

    if (maxLongEdge > 0) {
        opts.inJustDecodeBounds = true
        BitmapFactory.decodeFile(basePath, opts)
        if (opts.outWidth <= 0 || opts.outHeight <= 0) {
            throw IOException("cannot read base bounds")
        }
        var sample = 1
        val longEdgeHint = maxOf(opts.outWidth, opts.outHeight)
        while (longEdgeHint / sample > maxLongEdge) sample *= 2
        opts.inJustDecodeBounds = false
        opts.inSampleSize = sample
    } else {
        opts.inSampleSize = 1
    }

    var baseBmp = BitmapFactory.decodeFile(basePath, opts)
        ?: throw IOException("decode base failed")
    baseBmp = applyExifOrientation(baseBmp, basePath)

    try {
        if (maxLongEdge > 0) {
            val w = baseBmp.width
            val h = baseBmp.height
            val le = maxOf(w, h)
            if (le > maxLongEdge) {
                val scale = maxLongEdge.toFloat() / le
                val nw = max(1, (w * scale).roundToInt())
                val nh = max(1, (h * scale).roundToInt())
                val scaled = Bitmap.createScaledBitmap(baseBmp, nw, nh, true)
                if (scaled != baseBmp) {
                    baseBmp.recycle()
                    baseBmp = scaled
                }
            }
        }

        val overlayBmp = BitmapFactory.decodeByteArray(overlayPng, 0, overlayPng.size)
            ?: throw IOException("decode overlay failed")

        try {
            val working = baseBmp.copy(Bitmap.Config.ARGB_8888, true)
                ?: throw IOException("copy base failed")
            if (working != baseBmp) {
                baseBmp.recycle()
                baseBmp = working
            }

            val canvas = Canvas(baseBmp)
            val bw = baseBmp.width.toFloat()
            val bh = baseBmp.height.toFloat()
            val ow = overlayBmp.width.toFloat()
            val oh = overlayBmp.height.toFloat()
            if (ow < 1f || oh < 1f) throw IOException("bad overlay size")

            val scaleFactor = min(bw / ow, bh / oh)
            val matrix = Matrix().apply {
                reset()
                postScale(scaleFactor, scaleFactor)
                postTranslate((bw - ow * scaleFactor) / 2f, (bh - oh * scaleFactor) / 2f)
            }
            val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
                isFilterBitmap = true
            }
            canvas.drawBitmap(overlayBmp, matrix, paint)
        } finally {
            overlayBmp.recycle()
        }

        val outFile = File(cacheDir, "wm_merge_${System.currentTimeMillis()}.jpg")
        FileOutputStream(outFile).use { fos ->
            if (!baseBmp.compress(Bitmap.CompressFormat.JPEG, jpegQuality, fos)) {
                throw IOException("jpeg compress failed")
            }
        }
        return outFile.absolutePath
    } finally {
        baseBmp.recycle()
    }
}

// 传感器竖拍常把像素存成横向，靠 EXIF 标记方向；合并前必须与预览一致转成「朝上」像素。
private fun applyExifOrientation(bitmap: Bitmap, absolutePath: String): Bitmap {
    return try {
        val exif = ExifInterface(absolutePath)
        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_UNDEFINED,
        )
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> bitmap.rotateAndReplace(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> bitmap.rotateAndReplace(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> bitmap.rotateAndReplace(270f)
            else -> bitmap
        }
    } catch (_: Throwable) {
        bitmap
    }
}

private fun Bitmap.rotateAndReplace(degrees: Float): Bitmap {
    if (degrees == 0f) return this
    val matrix = Matrix().apply { postRotate(degrees) }
    val out = Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    if (out !== this && !this.isRecycled) {
        recycle()
    }
    return out
}
