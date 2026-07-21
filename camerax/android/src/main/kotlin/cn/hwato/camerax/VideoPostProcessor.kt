package cn.hwato.camerax

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

@OptIn(UnstableApi::class)
object VideoPostProcessor {
    private const val TAG = "VideoPostProcessor"

    data class OverlayKeyframe(
        val offsetMs: Long,
        val bitmap: Bitmap,
    )

    fun mergeVideoWithOverlayBytes(
        context: Context,
        inputPath: String,
        overlayBytes: ByteArray,
        outputPath: String,
        keyframePaths: List<Pair<Long, String>> = emptyList(),
    ): Boolean {
        if (overlayBytes.isEmpty()) return false
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val overlay = BitmapFactory.decodeByteArray(overlayBytes, 0, overlayBytes.size, options)
            ?: return false
        val keyframes = loadKeyframes(keyframePaths, options)
        return mergeVideoWithOverlayBitmap(
            context = context,
            inputPath = inputPath,
            fallbackOverlay = overlay,
            keyframes = keyframes,
            outputPath = outputPath,
        )
    }

    fun mergeVideoWithOverlayPath(
        context: Context,
        inputPath: String,
        overlayPath: String,
        outputPath: String,
        keyframePaths: List<Pair<Long, String>> = emptyList(),
    ): Boolean {
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val overlay = BitmapFactory.decodeFile(overlayPath, options) ?: return false
        val keyframes = loadKeyframes(keyframePaths, options)
        return mergeVideoWithOverlayBitmap(
            context = context,
            inputPath = inputPath,
            fallbackOverlay = overlay,
            keyframes = keyframes,
            outputPath = outputPath,
        )
    }

    private fun loadKeyframes(
        keyframePaths: List<Pair<Long, String>>,
        options: BitmapFactory.Options,
    ): List<OverlayKeyframe> {
        val keyframes = mutableListOf<OverlayKeyframe>()
        for ((offsetMs, path) in keyframePaths) {
            val bitmap = BitmapFactory.decodeFile(path, options) ?: continue
            keyframes.add(OverlayKeyframe(offsetMs, bitmap))
        }
        return keyframes.sortedBy { it.offsetMs }
    }

    private fun mergeVideoWithOverlayBitmap(
        context: Context,
        inputPath: String,
        fallbackOverlay: Bitmap,
        keyframes: List<OverlayKeyframe>,
        outputPath: String,
    ): Boolean {
        if (!waitForInputReady(inputPath)) {
            Log.e(TAG, "input video not ready: $inputPath")
            return false
        }

        val retriever = MediaMetadataRetriever()
        val overlayCopies = mutableListOf<Bitmap>()
        return try {
            retriever.setDataSource(inputPath)
            val rawWidth = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH,
            )?.toIntOrNull() ?: return false
            val rawHeight = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT,
            )?.toIntOrNull() ?: return false
            val rotation = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION,
            )?.toIntOrNull() ?: 0
            val durationMs = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION,
            )?.toLongOrNull()?.coerceAtLeast(1L) ?: return false
            if (rawWidth <= 0 || rawHeight <= 0) return false

            val (frameWidth, frameHeight) = displaySize(rawWidth, rawHeight, rotation)

            File(outputPath).parentFile?.mkdirs()
            File(outputPath).delete()

            val timeline = if (keyframes.isEmpty()) {
                listOf(OverlayKeyframe(0L, fallbackOverlay))
            } else {
                keyframes
            }

            var merged = if (timeline.size == 1) {
                val overlay = timeline.first().bitmap
                val frameOverlay = buildFullFrameOverlay(overlay, frameWidth, frameHeight)
                overlayCopies.add(frameOverlay)
                exportSingleOverlay(context, inputPath, frameOverlay, outputPath)
            } else {
                exportSegmentedOverlays(
                    context = context,
                    inputPath = inputPath,
                    timeline = timeline,
                    frameWidth = frameWidth,
                    frameHeight = frameHeight,
                    durationMs = durationMs,
                    outputPath = outputPath,
                    overlayCopies = overlayCopies,
                )
            }
            if (!merged) {
                Log.e(TAG, "primary merge failed, retry single overlay")
                val retryOverlay = timeline.last().bitmap
                val frameOverlay = buildFullFrameOverlay(retryOverlay, frameWidth, frameHeight)
                overlayCopies.add(frameOverlay)
                merged = exportSingleOverlay(context, inputPath, frameOverlay, outputPath)
            }
            merged
        } catch (e: Exception) {
            Log.e(TAG, "merge video overlay exception", e)
            false
        } finally {
            retriever.release()
            fallbackOverlay.recycle()
            keyframes.forEach { it.bitmap.recycle() }
            overlayCopies.forEach { it.recycle() }
        }
    }

    private fun displaySize(width: Int, height: Int, rotation: Int): Pair<Int, Int> {
        return if (rotation == 90 || rotation == 270) {
            height to width
        } else {
            width to height
        }
    }

    private fun exportSingleOverlay(
        context: Context,
        inputPath: String,
        overlay: Bitmap,
        outputPath: String,
    ): Boolean {
        val mediaItem = MediaItem.fromUri(Uri.fromFile(File(inputPath)))
        val overlayEffect = createOverlayEffect(overlay)
        val editedItem = EditedMediaItem.Builder(mediaItem)
            .setEffects(Effects(emptyList(), listOf(overlayEffect)))
            .build()
        val sequence = EditedMediaItemSequence(listOf(editedItem))
        val composition = Composition.Builder(listOf(sequence)).build()
        return exportComposition(context, composition, outputPath)
    }

    private fun exportSegmentedOverlays(
        context: Context,
        inputPath: String,
        timeline: List<OverlayKeyframe>,
        frameWidth: Int,
        frameHeight: Int,
        durationMs: Long,
        outputPath: String,
        overlayCopies: MutableList<Bitmap>,
    ): Boolean {
        val editedItems = timeline.mapIndexed { index, keyframe ->
            val startMs = keyframe.offsetMs.coerceAtLeast(0L)
            val endMs = if (index + 1 < timeline.size) {
                timeline[index + 1].offsetMs.coerceAtLeast(startMs + 1L)
            } else {
                durationMs
            }
            val frameOverlay = buildFullFrameOverlay(
                overlay = keyframe.bitmap,
                fullWidth = frameWidth,
                fullHeight = frameHeight,
            )
            overlayCopies.add(frameOverlay)
            val overlayEffect = createOverlayEffect(frameOverlay)
            EditedMediaItem.Builder(
                MediaItem.Builder()
                    .setUri(Uri.fromFile(File(inputPath)))
                    .setClippingConfiguration(
                        MediaItem.ClippingConfiguration.Builder()
                            .setStartPositionMs(startMs)
                            .setEndPositionMs(endMs.coerceAtMost(durationMs))
                            .build(),
                    )
                    .build(),
            )
                .setEffects(Effects(emptyList(), listOf(overlayEffect)))
                .build()
        }
        val sequence = EditedMediaItemSequence(editedItems)
        val composition = Composition.Builder(listOf(sequence)).build()
        return exportComposition(context, composition, outputPath)
    }

    private fun createOverlayEffect(overlay: Bitmap): OverlayEffect {
        val bitmapOverlay = BitmapOverlay.createStaticBitmapOverlay(overlay)
        return OverlayEffect(listOf(bitmapOverlay))
    }

    private fun buildFullFrameOverlay(
        overlay: Bitmap,
        fullWidth: Int,
        fullHeight: Int,
    ): Bitmap {
        val output = Bitmap.createBitmap(fullWidth, fullHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val dest = android.graphics.Rect(0, 0, fullWidth, fullHeight)
        canvas.drawBitmap(overlay, null, dest, null)
        return output
    }

    private fun waitForInputReady(path: String): Boolean {
        val file = File(path)
        var lastSize = -1L
        repeat(40) {
            if (!file.exists()) {
                Thread.sleep(50)
                return@repeat
            }
            val size = file.length()
            if (size > 0 && size == lastSize) {
                return true
            }
            lastSize = size
            Thread.sleep(50)
        }
        return file.exists() && file.length() > 0
    }

    fun exportCompositionPublic(
        context: Context,
        composition: Composition,
        outputPath: String,
    ): Boolean = exportComposition(context, composition, outputPath)

    private fun exportComposition(
        context: Context,
        composition: Composition,
        outputPath: String,
    ): Boolean {
        val latch = CountDownLatch(1)
        val success = AtomicBoolean(false)
        val exportError = AtomicReference<ExportException?>(null)
        val transformer = Transformer.Builder(context)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, result: ExportResult) {
                    success.set(true)
                    latch.countDown()
                }

                override fun onError(
                    composition: Composition,
                    result: ExportResult,
                    exception: ExportException,
                ) {
                    exportError.set(exception)
                    Log.e(TAG, "media3 overlay failed", exception)
                    latch.countDown()
                }
            })
            .build()

        val mainHandler = Handler(Looper.getMainLooper())
        mainHandler.post { transformer.start(composition, outputPath) }
        if (!latch.await(10, TimeUnit.MINUTES)) {
            Log.e(TAG, "media3 overlay timed out")
            return false
        }
        if (!success.get()) {
            exportError.get()?.let {
                Log.e(TAG, "media3 overlay export error: ${it.errorCodeName}")
            }
            return false
        }
        return File(outputPath).exists() && File(outputPath).length() > 0
    }
}
