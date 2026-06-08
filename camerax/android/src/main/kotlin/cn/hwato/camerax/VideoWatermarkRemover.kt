package cn.hwato.camerax

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.Crop
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import java.io.File

@OptIn(UnstableApi::class)
object VideoWatermarkRemover {
    private const val TAG = "VideoWatermarkRemover"

    fun remove(context: Context, inputPath: String, outputPath: String): Boolean {
        if (!File(inputPath).exists()) return false
        File(outputPath).parentFile?.mkdirs()
        File(outputPath).delete()

        if (removeWithDynamicHealOverlay(context, inputPath, outputPath)) {
            return true
        }
        Log.w(TAG, "dynamic heal failed, fallback to crop")
        return removeWithBottomCrop(context, inputPath, outputPath)
    }

    private fun removeWithDynamicHealOverlay(
        context: Context,
        inputPath: String,
        outputPath: String,
    ): Boolean {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(inputPath)
            val width = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH,
            )?.toIntOrNull() ?: return false
            val height = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT,
            )?.toIntOrNull() ?: return false
            if (width <= 0 || height <= 0) return false

            val dynamicOverlay = HealPatchBitmapOverlay(
                retriever = retriever,
                frameWidth = width,
                frameHeight = height,
            )
            val overlayEffect = OverlayEffect(listOf(dynamicOverlay))
            val mediaItem = MediaItem.fromUri(Uri.fromFile(File(inputPath)))
            val editedItem = EditedMediaItem.Builder(mediaItem)
                .setEffects(Effects(emptyList(), listOf(overlayEffect)))
                .build()
            val sequence = EditedMediaItemSequence(listOf(editedItem))
            val composition = Composition.Builder(listOf(sequence)).build()
            VideoPostProcessor.exportCompositionPublic(context, composition, outputPath)
        } catch (e: Exception) {
            Log.e(TAG, "dynamic heal overlay failed", e)
            false
        } finally {
            retriever.release()
        }
    }

    private class HealPatchBitmapOverlay(
        private val retriever: MediaMetadataRetriever,
        private val frameWidth: Int,
        private val frameHeight: Int,
    ) : BitmapOverlay() {
        override fun getBitmap(presentationTimeUs: Long): Bitmap {
            return buildHealPatchOverlay(
                retriever = retriever,
                presentationTimeUs = presentationTimeUs,
                targetWidth = frameWidth,
                targetHeight = frameHeight,
            )
        }
    }

    private fun buildHealPatchOverlay(
        retriever: MediaMetadataRetriever,
        presentationTimeUs: Long,
        targetWidth: Int,
        targetHeight: Int,
    ): Bitmap {
        val overlay = Bitmap.createBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
        val frame = retriever.getFrameAtTime(
            presentationTimeUs,
            MediaMetadataRetriever.OPTION_CLOSEST,
        )
        if (frame == null) {
            return overlay
        }

        val scaled = if (frame.width != targetWidth || frame.height != targetHeight) {
            Bitmap.createScaledBitmap(frame, targetWidth, targetHeight, true).also {
                if (it !== frame) {
                    frame.recycle()
                }
            }
        } else {
            frame
        }

        val healed = healBottomWatermark(scaled)
        val cropHeight = (targetHeight * 0.22f).toInt().coerceAtLeast(1)
        val cropWidth = (targetWidth * 0.72f).toInt().coerceAtLeast(1)
        val top = (targetHeight - cropHeight - (targetHeight * 0.04f).toInt())
            .coerceIn(0, targetHeight - 1)

        val canvas = Canvas(overlay)
        val src = Rect(0, top, cropWidth.coerceAtMost(targetWidth), targetHeight)
        val dst = Rect(0, top, cropWidth.coerceAtMost(targetWidth), targetHeight)
        canvas.drawBitmap(healed, src, dst, null)

        if (healed !== scaled) {
            healed.recycle()
        }
        if (scaled !== frame) {
            scaled.recycle()
        } else {
            frame.recycle()
        }
        return overlay
    }

    private fun removeWithBottomCrop(
        context: Context,
        inputPath: String,
        outputPath: String,
    ): Boolean {
        val crop = Crop(
            /* left= */ 0f,
            /* right= */ 1f,
            /* top= */ 0f,
            /* bottom= */ 0.78f,
        )
        val mediaItem = MediaItem.fromUri(Uri.fromFile(File(inputPath)))
        val editedItem = EditedMediaItem.Builder(mediaItem)
            .setEffects(Effects(emptyList(), listOf(crop)))
            .build()
        val sequence = EditedMediaItemSequence(listOf(editedItem))
        val composition = Composition.Builder(listOf(sequence)).build()
        return VideoPostProcessor.exportCompositionPublic(context, composition, outputPath)
    }

    private fun healBottomWatermark(bitmap: Bitmap): Bitmap {
        val output = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val cropHeight = (output.height * 0.22f).toInt().coerceAtLeast(1)
        val cropWidth = (output.width * 0.72f).toInt().coerceAtLeast(1)
        val sampleY = (output.height - cropHeight - (output.height * 0.04f).toInt())
            .coerceIn(0, output.height - 1)
        for (y in sampleY until output.height) {
            for (x in 0 until cropWidth) {
                val safeX = x.coerceAtMost(output.width - 1)
                output.setPixel(safeX, y, output.getPixel(safeX, sampleY))
            }
        }
        return output
    }
}
