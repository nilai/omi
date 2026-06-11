package ai.memopin.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

/**
 * 首页长录音：原生 MediaRecorder + 混音音频焦点 + 打断后自动续录新分段。
 */
object MPNativeRecorderPlugin {
    private const val CHANNEL = "mp_native_recorder"
    private const val EVENT_CHANNEL = "mp_native_recorder/events"

    private var appContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var mainHandler: Handler? = null

    private var mixWithOthers = false
    private var recorder: MediaRecorder? = null
    private var currentPath: String? = null
    private val segmentPaths = mutableListOf<String>()

    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                if (recorder != null) {
                    pauseSegmentInternal()
                    if (mixWithOthers) {
                        mainHandler?.postDelayed({ tryAutoResumeSegment() }, 300L)
                    }
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                if (mixWithOthers && recorder == null) {
                    tryAutoResumeSegment()
                }
            }
        }
    }

    fun register(context: Context, flutterEngine: FlutterEngine) {
        appContext = context.applicationContext
        mainHandler = Handler(Looper.getMainLooper())
        audioManager = appContext?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> {
                        mixWithOthers = call.argument<Boolean>("mixWithOthers") ?: false
                        requestAudioFocus()
                        result.success(true)
                    }
                    "close" -> {
                        releaseRecorderOnly()
                        abandonAudioFocus()
                        mixWithOthers = false
                        result.success(null)
                    }
                    "start" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) false else startRecording(path))
                    }
                    "pauseSegment" -> result.success(pauseSegmentInternal())
                    "finish" -> {
                        val outputPath = call.argument<String>("outputPath")
                        result.success(if (outputPath.isNullOrBlank()) null else finish(outputPath))
                    }
                    "isRecording" -> result.success(recorder != null)
                    "currentPath" -> result.success(currentPath)
                    "fileSize" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) 0 else fileSize(path))
                    }
                    "segmentPaths" -> {
                        val paths = segmentPaths.toMutableList()
                        currentPath?.let { if (!paths.contains(it)) paths.add(it) }
                        result.success(paths)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    private fun requestAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(
                    if (mixWithOthers) AudioAttributes.USAGE_MEDIA
                    else AudioAttributes.USAGE_VOICE_COMMUNICATION,
                )
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val focusGain = if (mixWithOthers) {
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            } else {
                AudioManager.AUDIOFOCUS_GAIN
            }
            audioFocusRequest = AudioFocusRequest.Builder(focusGain)
                .setAudioAttributes(attrs)
                .setWillPauseWhenDucked(false)
                .setOnAudioFocusChangeListener(focusChangeListener, mainHandler!!)
                .build()
            manager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                focusChangeListener,
                AudioManager.STREAM_MUSIC,
                if (mixWithOthers) AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                else AudioManager.AUDIOFOCUS_GAIN,
            )
        }
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { manager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(focusChangeListener)
        }
        audioFocusRequest = null
    }

    private fun startRecording(path: String): Boolean {
        releaseRecorderOnly()
        return try {
            val file = File(path)
            file.parentFile?.mkdirs()
            val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(appContext!!)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mediaRecorder.setAudioSamplingRate(8000)
            mediaRecorder.setAudioChannels(1)
            mediaRecorder.setAudioEncodingBitRate(8000)
            mediaRecorder.setOutputFile(path)
            mediaRecorder.prepare()
            mediaRecorder.start()
            recorder = mediaRecorder
            currentPath = path
            true
        } catch (_: Exception) {
            releaseRecorderOnly()
            false
        }
    }

    private fun releaseRecorderOnly() {
        try {
            recorder?.stop()
        } catch (_: Exception) {
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
    }

    private fun pauseSegmentInternal(): String? {
        val path = currentPath ?: return null
        releaseRecorderOnly()
        if (!segmentPaths.contains(path)) {
            segmentPaths.add(path)
        }
        currentPath = null
        return path
    }

    private fun tryAutoResumeSegment() {
        if (recorder != null) return
        requestAudioFocus()
        val dir = directoryForAutoSegment() ?: return
        val path = File(
            dir,
            "omi_focus_${System.currentTimeMillis()}_${segmentPaths.size}.m4a",
        ).absolutePath
        if (startRecording(path)) {
            mainHandler?.post {
                eventSink?.success(mapOf("type" to "segmentAutoStarted", "path" to path))
            }
        }
    }

    private fun directoryForAutoSegment(): File? {
        currentPath?.let { return File(it).parentFile }
        segmentPaths.lastOrNull()?.let { return File(it).parentFile }
        return appContext?.cacheDir
    }

    private fun finish(outputPath: String): String? {
        if (recorder != null) {
            pauseSegmentInternal()
        }
        val inputs = segmentPaths.toList()
        segmentPaths.clear()
        if (inputs.isEmpty()) return null
        if (inputs.size == 1) {
            val single = inputs[0]
            if (single == outputPath) return single
            File(outputPath).delete()
            return if (File(single).renameTo(File(outputPath))) outputPath else single
        }
        return if (mergeM4aFiles(inputs, outputPath)) {
            inputs.filter { it != outputPath }.forEach { File(it).delete() }
            outputPath
        } else {
            inputs.last()
        }
    }

    private fun mergeM4aFiles(inputPaths: List<String>, outputPath: String): Boolean {
        if (inputPaths.isEmpty()) return false
        File(outputPath).delete()
        var muxer: MediaMuxer? = null
        var outputTrackIndex = -1
        var timeOffsetUs = 0L
        val buffer = ByteBuffer.allocate(256 * 1024)
        val bufferInfo = MediaCodec.BufferInfo()
        try {
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            for (inputPath in inputPaths) {
                val extractor = MediaExtractor()
                extractor.setDataSource(inputPath)
                val trackIndex = selectAudioTrack(extractor)
                if (trackIndex < 0) {
                    extractor.release()
                    continue
                }
                extractor.selectTrack(trackIndex)
                val format = extractor.getTrackFormat(trackIndex)
                if (outputTrackIndex < 0) {
                    outputTrackIndex = muxer.addTrack(format)
                    muxer.start()
                }
                while (true) {
                    buffer.clear()
                    val sampleSize = extractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break
                    bufferInfo.offset = 0
                    bufferInfo.size = sampleSize
                    bufferInfo.presentationTimeUs = extractor.sampleTime + timeOffsetUs
                    bufferInfo.flags = extractor.sampleFlags
                    muxer.writeSampleData(outputTrackIndex, buffer, bufferInfo)
                    if (!extractor.advance()) break
                }
                timeOffsetUs += extractor.getTrackFormat(trackIndex).getLong(MediaFormat.KEY_DURATION)
                extractor.release()
            }
            return outputTrackIndex >= 0
        } catch (_: Exception) {
            return false
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
            }
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) return i
        }
        return -1
    }

    private fun fileSize(path: String): Int {
        return File(path).length().toInt()
    }
}
