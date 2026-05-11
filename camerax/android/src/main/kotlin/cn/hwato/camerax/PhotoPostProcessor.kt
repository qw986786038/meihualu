package cn.hwato.camerax

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.FileOutputStream
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * EXIF 方向校正后按 [aspectRatio]（宽/高）做中心裁剪，再输出 JPEG。
 */
object PhotoPostProcessor {

    fun mergeCaptureWithOverlay(
        inputPath: String,
        overlayPath: String,
        outputPath: String,
        quality: Int,
    ): Boolean {
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val overlay = BitmapFactory.decodeFile(overlayPath, options) ?: return false
        return mergeCaptureWithOverlayBitmap(inputPath, overlay, outputPath, quality)
    }

    fun mergeCaptureWithOverlayBytes(
        inputPath: String,
        overlayBytes: ByteArray,
        outputPath: String,
        quality: Int,
    ): Boolean {
        if (overlayBytes.isEmpty()) return false
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val overlay = BitmapFactory.decodeByteArray(overlayBytes, 0, overlayBytes.size, options) ?: return false
        return mergeCaptureWithOverlayBitmap(inputPath, overlay, outputPath, quality)
    }

    private fun mergeCaptureWithOverlayBitmap(
        inputPath: String,
        overlay: Bitmap,
        outputPath: String,
        quality: Int,
    ): Boolean {
        val q = quality.coerceIn(1, 100)
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        var base = BitmapFactory.decodeFile(inputPath, options) ?: return false
        base = applyExifOrientation(inputPath, base)
        if (base.width <= 0 || base.height <= 0) {
            base.recycle()
            overlay.recycle()
            return false
        }

        val canvas = Canvas(base)
        canvas.drawBitmap(
            overlay,
            null,
            Rect(0, 0, base.width, base.height),
            null
        )
        overlay.recycle()

        val ok = writeJpeg(base, outputPath, q)
        base.recycle()
        return ok
    }

    fun processCaptureImage(
        inputPath: String,
        outputPath: String,
        aspectRatio: Double,
        quality: Int,
    ): Boolean {
        if (aspectRatio <= 0 || !aspectRatio.isFinite()) return false
        val q = quality.coerceIn(1, 100)

        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        var bitmap = BitmapFactory.decodeFile(inputPath, options) ?: return false
        bitmap = applyExifOrientation(inputPath, bitmap)

        val w = bitmap.width
        val h = bitmap.height
        if (w <= 0 || h <= 0) {
            bitmap.recycle()
            return false
        }

        val sourceAspect = w.toDouble() / h.toDouble()
        if (abs(sourceAspect - aspectRatio) < 0.01) {
            val ok = writeJpeg(bitmap, outputPath, q)
            bitmap.recycle()
            return ok
        }

        var cropW = w
        var cropH = h
        if (sourceAspect > aspectRatio) {
            cropW = (h * aspectRatio).roundToInt()
        } else {
            cropH = (w / aspectRatio).roundToInt()
        }
        cropW = cropW.coerceIn(1, w)
        cropH = cropH.coerceIn(1, h)
        val left = ((w - cropW) / 2f).roundToInt().coerceIn(0, w - cropW)
        val top = ((h - cropH) / 2f).roundToInt().coerceIn(0, h - cropH)

        val cropped = Bitmap.createBitmap(bitmap, left, top, cropW, cropH)
        bitmap.recycle()

        val ok = writeJpeg(cropped, outputPath, q)
        cropped.recycle()
        return ok
    }

    private fun writeJpeg(bitmap: Bitmap, outputPath: String, quality: Int): Boolean {
        return try {
            FileOutputStream(outputPath).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun applyExifOrientation(path: String, bitmap: Bitmap): Bitmap {
        return try {
            val exif = ExifInterface(path)
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
            val matrix = Matrix()
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
                ExifInterface.ORIENTATION_TRANSPOSE -> {
                    matrix.postRotate(90f)
                    matrix.postScale(-1f, 1f)
                }
                ExifInterface.ORIENTATION_TRANSVERSE -> {
                    matrix.postRotate(270f)
                    matrix.postScale(-1f, 1f)
                }
                else -> return bitmap
            }
            val out = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            bitmap.recycle()
            out
        } catch (_: Exception) {
            bitmap
        }
    }
}
