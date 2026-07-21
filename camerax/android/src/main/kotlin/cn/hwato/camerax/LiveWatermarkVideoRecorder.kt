package cn.hwato.camerax

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.min

class LiveWatermarkVideoRecorder {
    private var muxer: MediaMuxer? = null
    private var videoEncoder: MediaCodec? = null
    private var audioEncoder: MediaCodec? = null
    private var audioRecord: AudioRecord? = null
    private var audioThread: Thread? = null
    private var overlayBitmap: Bitmap? = null
    private var outputPath: String? = null
    private var videoTrackIndex = -1
    private var audioTrackIndex = -1
    private var muxerStarted = false
    private var videoWidth = 0
    private var videoHeight = 0
    private var frameIndex = 0L
    private var encodedFrameIndex = 0L
    private val frameDurationUs = 1_000_000L / FRAME_RATE
    private var lastQueuedPresentationTimeUs = 0L
    private val stopped = AtomicBoolean(false)
    private val processing = AtomicBoolean(false)
    private var audioEnabled = false
    private var captureAspectRatio = 0f
    private var videoSamplesWritten = 0
    private var lastEncodedNv12: ByteArray? = null
    private var ptsOriginUs = -1L

    fun start(
        output: String,
        overlayBytes: ByteArray?,
        captureAspectRatio: Float = 0f,
    ): Boolean {
        return try {
            stopInternal()
            stopped.set(false)
            encodedFrameIndex = 0L
            ptsOriginUs = -1L
            outputPath = output
            this.captureAspectRatio = captureAspectRatio
            File(output).parentFile?.mkdirs()
            File(output).delete()
            updateOverlay(overlayBytes)
            true
        } catch (e: Exception) {
            Log.e(TAG, "start live recorder failed", e)
            stopInternal()
            false
        }
    }

    fun updateOverlay(overlayBytes: ByteArray?) {
        if (overlayBytes == null || overlayBytes.isEmpty()) return
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = BitmapFactory.decodeByteArray(overlayBytes, 0, overlayBytes.size, options)
            ?: return
        overlayBitmap?.recycle()
        overlayBitmap = decoded
    }

    fun encodeNv21Frame(
        nv21: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
        captureTimeUs: Long,
    ): Boolean {
        if (stopped.get()) return false
        if (!processing.compareAndSet(false, true)) return false
        return try {
            val expectedNv21 = width * height + width * height / 2
            if (width <= 0 || height <= 0 || nv21.size < expectedNv21) return false
            val frameBitmap = nv21ToBitmap(nv21, width, height) ?: return false
            val rotated = rotateBitmap(frameBitmap, rotation)
            if (rotated !== frameBitmap) {
                frameBitmap.recycle()
            }
            ensureEncoders(rotated.width, rotated.height)
            val aspect = resolveAspectRatio(rotated.width, rotated.height)
            val cropped = centerCropToAspect(rotated, aspect)
            if (cropped !== rotated) {
                rotated.recycle()
            }
            val scaled = scaleBitmapUniform(cropped, videoWidth, videoHeight)
            if (scaled !== cropped) {
                cropped.recycle()
            }
            val composited = compositeOverlay(scaled, overlayBitmap)
            val yuv = bitmapToNv12(composited)
            composited.recycle()
            enqueueVideoFrame(yuv, captureTimeUs)
            true
        } catch (e: Exception) {
            Log.e(TAG, "encode frame failed", e)
            false
        } finally {
            processing.set(false)
        }
    }

    fun stop(recordingEndUs: Long = 0L): Boolean {
        stopped.set(true)
        waitForProcessingIdle()
        stopAudioCaptureSafely()
        return try {
            if (videoEncoder != null && encodedFrameIndex > 0) {
                val normalizedEndUs = normalizeRecordingEndUs(recordingEndUs)
                padVideoToRecordingEnd(normalizedEndUs)
                signalVideoEndOfStream()
                drainVideo(end = true)
                if (audioEnabled) {
                    drainAudio(end = true)
                }
            }
            stopInternal(releaseEmptyMuxer = encodedFrameIndex <= 0)
            val path = outputPath
            path != null && File(path).exists() && File(path).length() > 0
        } catch (e: Exception) {
            Log.e(TAG, "stop live recorder failed", e)
            stopInternal(releaseEmptyMuxer = true)
            false
        }
    }

    private fun waitForProcessingIdle() {
        repeat(150) {
            if (!processing.get()) return
            Thread.sleep(20)
        }
    }

    private fun stopAudioCaptureSafely() {
        try {
            audioThread?.join(2000)
        } catch (_: Exception) {
        }
        audioThread = null
        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }
        audioRecord?.release()
        audioRecord = null
    }

    private fun ensureEncoders(rotatedWidth: Int, rotatedHeight: Int) {
        if (videoEncoder != null) return
        val aspect = resolveAspectRatio(rotatedWidth, rotatedHeight)
        val cropWidth = computeCropWidth(rotatedWidth, rotatedHeight, aspect)
        val cropHeight = computeCropHeight(rotatedWidth, rotatedHeight, aspect)
        val (outWidth, outHeight) = computeOutputSize(cropWidth, cropHeight)
        videoWidth = outWidth
        videoHeight = outHeight

        muxer = MediaMuxer(outputPath!!, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        val videoFormat = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, videoWidth, videoHeight)
        videoFormat.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar,
        )
        videoFormat.setInteger(MediaFormat.KEY_BIT_RATE, 3_500_000)
        videoFormat.setInteger(MediaFormat.KEY_FRAME_RATE, FRAME_RATE)
        videoFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)

        videoEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC).apply {
            configure(videoFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }
        // 实时录像仅保留视频轨，避免音频线程在 stop 时引发崩溃。
    }

    private fun startAudioCapture() {
        audioEnabled = false
        try {
            val audioEncoderLocal = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            val audioFormat = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, SAMPLE_RATE, 1)
            audioFormat.setInteger(MediaFormat.KEY_BIT_RATE, 96_000)
            audioFormat.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            audioEncoderLocal.configure(audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            audioEncoderLocal.start()
            audioEncoder = audioEncoderLocal

            val minBuffer = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            if (minBuffer <= 0) {
                throw IllegalStateException("invalid audio buffer size: $minBuffer")
            }
            val record = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                max(minBuffer, 4096) * 2,
            )
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                record.release()
                throw IllegalStateException("audio record not initialized")
            }
            record.startRecording()
            audioRecord = record
            audioEnabled = true
            audioThread = Thread({ audioLoop() }, "wm-audio-loop").also { it.start() }
        } catch (e: Exception) {
            Log.w(TAG, "audio capture unavailable, recording video only", e)
            try {
                audioRecord?.stop()
            } catch (_: Exception) {
            }
            audioRecord?.release()
            audioRecord = null
            try {
                audioEncoder?.stop()
            } catch (_: Exception) {
            }
            audioEncoder?.release()
            audioEncoder = null
            audioTrackIndex = -1
            audioEnabled = false
        }
    }

    private fun audioLoop() {
        val localRecord = audioRecord ?: return
        val localEncoder = audioEncoder ?: return
        val buffer = ByteArray(4096)
        var audioPresentationUs = 0L
        val samplesPerBuffer = buffer.size / 2
        val bufferDurationUs = samplesPerBuffer * 1_000_000L / SAMPLE_RATE
        while (!stopped.get()) {
            val read = localRecord.read(buffer, 0, buffer.size)
            if (read <= 0) continue
            var offset = 0
            while (offset < read) {
                val inputIndex = localEncoder.dequeueInputBuffer(TIMEOUT_US)
                if (inputIndex < 0) break
                val capacity = localEncoder.getInputBuffer(inputIndex)?.capacity() ?: 0
                val chunk = min(capacity, read - offset)
                val inputBuffer = localEncoder.getInputBuffer(inputIndex) ?: break
                inputBuffer.clear()
                inputBuffer.put(buffer, offset, chunk)
                localEncoder.queueInputBuffer(
                    inputIndex,
                    0,
                    chunk,
                    audioPresentationUs,
                    0,
                )
                offset += chunk
                audioPresentationUs += bufferDurationUs
            }
            drainAudio(false)
        }
    }

    private fun normalizeCaptureTimeUs(captureTimeUs: Long): Long {
        if (ptsOriginUs < 0L) {
            ptsOriginUs = captureTimeUs
        }
        return max(captureTimeUs - ptsOriginUs, 0L)
    }

    private fun normalizeRecordingEndUs(recordingEndUs: Long): Long {
        if (recordingEndUs <= 0L) return recordingEndUs
        if (ptsOriginUs < 0L) return recordingEndUs
        return max(recordingEndUs - ptsOriginUs, 0L)
    }

    private fun padVideoToRecordingEnd(recordingEndUs: Long) {
        val normalizedEnd = normalizeRecordingEndUs(recordingEndUs)
        if (normalizedEnd <= 0L) return
        val targetFinalIndex = normalizedEnd / frameDurationUs
        val lastFrame = lastEncodedNv12 ?: return
        while (encodedFrameIndex <= targetFinalIndex) {
            queueFrameAtIndex(lastFrame)
        }
    }

    private fun enqueueVideoFrame(nv12: ByteArray, captureTimeUs: Long) {
        val timelineUs = normalizeCaptureTimeUs(captureTimeUs)
        val targetIndex = (timelineUs / frameDurationUs).coerceAtLeast(encodedFrameIndex)
        val duplicates = lastEncodedNv12
        var filled = 0
        while (
            encodedFrameIndex < targetIndex &&
            duplicates != null &&
            filled < MAX_GAP_FILL_PER_FRAME
        ) {
            queueFrameAtIndex(duplicates)
            filled++
        }
        queueFrameAtIndex(nv12)
        lastEncodedNv12 = nv12.copyOf()
        frameIndex++
    }

    private fun queueFrameAtIndex(nv12: ByteArray) {
        val pts = encodedFrameIndex * frameDurationUs
        queueVideoFrameAtPts(nv12, pts)
        lastQueuedPresentationTimeUs = pts
        encodedFrameIndex++
    }

    private fun queueVideoFrameAtPts(nv12: ByteArray, ptsUs: Long) {
        val encoder = videoEncoder ?: return
        val inputIndex = encoder.dequeueInputBuffer(TIMEOUT_US)
        if (inputIndex < 0) return
        val inputBuffer = encoder.getInputBuffer(inputIndex) ?: return
        inputBuffer.clear()
        val chunkSize = min(nv12.size, inputBuffer.remaining())
        if (chunkSize <= 0) return
        inputBuffer.put(nv12, 0, chunkSize)
        encoder.queueInputBuffer(
            inputIndex,
            0,
            chunkSize,
            ptsUs,
            0,
        )
        drainVideo(false)
    }

    private fun signalVideoEndOfStream() {
        val encoder = videoEncoder ?: return
        repeat(10) {
            val inputIndex = encoder.dequeueInputBuffer(50_000L)
            if (inputIndex >= 0) {
                encoder.queueInputBuffer(
                    inputIndex,
                    0,
                    0,
                    lastQueuedPresentationTimeUs,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                )
                return
            }
        }
        val audioEncoder = audioEncoder ?: return
        repeat(10) {
            val audioInput = audioEncoder.dequeueInputBuffer(50_000L)
            if (audioInput >= 0) {
                audioEncoder.queueInputBuffer(
                    audioInput,
                    0,
                    0,
                    0,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                )
                return
            }
        }
    }

    private fun drainVideo(end: Boolean) {
        val encoder = videoEncoder ?: return
        val bufferInfo = MediaCodec.BufferInfo()
        val timeoutUs = if (end) 50_000L else TIMEOUT_US
        var idleRetries = 0
        while (true) {
            val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!end || idleRetries++ >= 20) return
                }
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerStarted) continue
                    val mux = muxer ?: return
                    videoTrackIndex = mux.addTrack(encoder.outputFormat)
                    maybeStartMuxer()
                }
                outputIndex >= 0 -> {
                    idleRetries = 0
                    val encoded = encoder.getOutputBuffer(outputIndex) ?: continue
                    if (bufferInfo.size > 0 && muxerStarted) {
                        encoded.position(bufferInfo.offset)
                        encoded.limit(bufferInfo.offset + bufferInfo.size)
                        muxer?.writeSampleData(videoTrackIndex, encoded, bufferInfo)
                        videoSamplesWritten++
                    }
                    encoder.releaseOutputBuffer(outputIndex, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        return
                    }
                    if (!end) return
                }
            }
        }
    }

    private fun drainAudio(end: Boolean) {
        val encoder = audioEncoder ?: return
        val bufferInfo = MediaCodec.BufferInfo()
        while (true) {
            val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> return
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerStarted) continue
                    val mux = muxer ?: return
                    audioTrackIndex = mux.addTrack(encoder.outputFormat)
                    maybeStartMuxer()
                }
                outputIndex >= 0 -> {
                    val encoded = encoder.getOutputBuffer(outputIndex) ?: continue
                    if (bufferInfo.size > 0 && muxerStarted) {
                        encoded.position(bufferInfo.offset)
                        encoded.limit(bufferInfo.offset + bufferInfo.size)
                        muxer?.writeSampleData(audioTrackIndex, encoded, bufferInfo)
                    }
                    encoder.releaseOutputBuffer(outputIndex, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        return
                    }
                    if (!end) return
                }
            }
        }
    }

    private fun maybeStartMuxer() {
        if (muxerStarted) return
        if (videoTrackIndex < 0) return
        if (audioEnabled && audioTrackIndex < 0) return
        muxer?.start()
        muxerStarted = true
    }

    private fun stopInternal(releaseEmptyMuxer: Boolean = false) {
        stopAudioCaptureSafely()
        try {
            videoEncoder?.stop()
        } catch (_: Exception) {
        }
        try {
            audioEncoder?.stop()
        } catch (_: Exception) {
        }
        videoEncoder?.release()
        audioEncoder?.release()
        videoEncoder = null
        audioEncoder = null
        val shouldStopMuxer = muxerStarted && videoSamplesWritten > 0 && !releaseEmptyMuxer
        if (shouldStopMuxer) {
            try {
                muxer?.stop()
            } catch (e: Exception) {
                Log.w(TAG, "muxer stop failed", e)
            }
        } else if (releaseEmptyMuxer) {
            try {
                outputPath?.let { File(it).delete() }
            } catch (_: Exception) {
            }
        }
        try {
            muxer?.release()
        } catch (_: Exception) {
        }
        muxer = null
        muxerStarted = false
        videoTrackIndex = -1
        audioTrackIndex = -1
        overlayBitmap?.recycle()
        overlayBitmap = null
        frameIndex = 0
        encodedFrameIndex = 0
        lastQueuedPresentationTimeUs = 0
        videoSamplesWritten = 0
        lastEncodedNv12 = null
        ptsOriginUs = -1L
        videoWidth = 0
        videoHeight = 0
        captureAspectRatio = 0f
        audioEnabled = false
        processing.set(false)
    }

    private fun resolveAspectRatio(width: Int, height: Int): Float {
        if (captureAspectRatio > 0f) return captureAspectRatio
        if (width <= 0 || height <= 0) return 9f / 16f
        return width.toFloat() / height.toFloat()
    }

    private fun computeCropWidth(srcWidth: Int, srcHeight: Int, aspect: Float): Int {
        val srcAspect = srcWidth.toFloat() / srcHeight.toFloat()
        return if (srcAspect > aspect) {
            (srcHeight * aspect).toInt().coerceIn(1, srcWidth)
        } else {
            srcWidth
        }
    }

    private fun computeCropHeight(srcWidth: Int, srcHeight: Int, aspect: Float): Int {
        val srcAspect = srcWidth.toFloat() / srcHeight.toFloat()
        return if (srcAspect > aspect) {
            srcHeight
        } else {
            (srcWidth / aspect).toInt().coerceIn(1, srcHeight)
        }
    }

    private fun computeOutputSize(width: Int, height: Int): Pair<Int, Int> {
        val maxEdge = max(width, height)
        val scale = if (maxEdge > MAX_EDGE) MAX_EDGE.toFloat() / maxEdge.toFloat() else 1f
        return makeEven((width * scale).toInt()) to makeEven((height * scale).toInt())
    }

    private fun centerCropToAspect(bitmap: Bitmap, aspect: Float): Bitmap {
        val srcAspect = bitmap.width.toFloat() / bitmap.height.toFloat()
        if (kotlin.math.abs(srcAspect - aspect) < 0.01f) {
            return bitmap
        }
        return if (srcAspect > aspect) {
            val cropWidth = (bitmap.height * aspect).toInt().coerceIn(1, bitmap.width)
            val left = (bitmap.width - cropWidth) / 2
            Bitmap.createBitmap(bitmap, left, 0, cropWidth, bitmap.height)
        } else {
            val cropHeight = (bitmap.width / aspect).toInt().coerceIn(1, bitmap.height)
            val top = (bitmap.height - cropHeight) / 2
            Bitmap.createBitmap(bitmap, 0, top, bitmap.width, cropHeight)
        }
    }

    private fun nv21ToBitmap(nv21: ByteArray, width: Int, height: Int): Bitmap? {
        return try {
            val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            val jpegOut = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 80, jpegOut)
            val maxDim = max(width, height)
            val sampleSize = when {
                maxDim > MAX_EDGE * 3 -> 4
                maxDim > MAX_EDGE * 2 -> 2
                else -> 1
            }
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.ARGB_8888
                inSampleSize = sampleSize
            }
            BitmapFactory.decodeByteArray(
                jpegOut.toByteArray(),
                0,
                jpegOut.size(),
                options,
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, rotation: Int): Bitmap {
        val normalized = ((rotation % 360) + 360) % 360
        if (normalized == 0) return bitmap
        val matrix = Matrix().apply { postRotate(normalized.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun scaleBitmapUniform(bitmap: Bitmap, targetWidth: Int, targetHeight: Int): Bitmap {
        if (bitmap.width == targetWidth && bitmap.height == targetHeight) return bitmap
        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    private fun compositeOverlay(frame: Bitmap, overlay: Bitmap?): Bitmap {
        if (overlay == null) return frame
        val output = Bitmap.createBitmap(frame.width, frame.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        canvas.drawBitmap(frame, 0f, 0f, null)
        canvas.drawBitmap(
            overlay,
            null,
            Rect(0, 0, frame.width, frame.height),
            null,
        )
        frame.recycle()
        return output
    }

    private fun bitmapToNv12(bitmap: Bitmap): ByteArray {
        val width = bitmap.width
        val height = bitmap.height
        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)
        val yuv = ByteArray(width * height * 3 / 2)
        var yIndex = 0
        var uvIndex = width * height
        for (j in 0 until height) {
            for (i in 0 until width) {
                val color = argb[j * width + i]
                val r = (color shr 16) and 0xFF
                val g = (color shr 8) and 0xFF
                val b = color and 0xFF
                val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                yuv[yIndex++] = clamp(y).toByte()
                if (j % 2 == 0 && i % 2 == 0) {
                    yuv[uvIndex++] = clamp(u).toByte()
                    yuv[uvIndex++] = clamp(v).toByte()
                }
            }
        }
        return yuv
    }

    private fun clamp(value: Int): Int = max(0, min(255, value))

    private fun makeEven(value: Int): Int = if (value % 2 == 0) value else value - 1

    companion object {
        private const val TAG = "LiveWatermarkRecorder"
        private const val FRAME_RATE = 10
        private const val MAX_GAP_FILL_PER_FRAME = 10
        private const val SAMPLE_RATE = 44100
        private const val MAX_EDGE = 1080
        private const val TIMEOUT_US = 10_000L
    }
}
