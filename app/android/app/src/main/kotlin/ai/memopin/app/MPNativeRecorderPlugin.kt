package ai.memopin.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 首页长录音：原生 MediaRecorder 整段写入单文件；混音模式支持系统打断后自动续录。
 */
object MPNativeRecorderPlugin {
    private const val CHANNEL = "mp_native_recorder"
    private const val EVENT_CHANNEL = "mp_native_recorder/events"

    private var appContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var mixWithOthers = false
    private var recorder: MediaRecorder? = null
    private var currentPath: String? = null
    private var isPaused = false
    /** 系统音频焦点被抢占（来电、独占麦克风 App 等）。 */
    private var microphoneCaptureBlocked = false

    /** 已完成分段累计时长（毫秒）；录制中未 finalize 的 m4a 无法从文件读出时长。 */
    private var accumulatedDurationMs: Long = 0

    /** 当前连续录制段起点（[SystemClock.elapsedRealtime]）。 */
    private var activeSegmentStartedAtMs: Long? = null

    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        if (!mixWithOthers) {
            return@OnAudioFocusChangeListener
        }
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE -> {
                microphoneCaptureBlocked = false
                eventSink?.success(mapOf("type" to "interruptionEnded"))
            }
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                microphoneCaptureBlocked = true
                pauseRecordingInternal()
                eventSink?.success(mapOf("type" to "interruptionBegan"))
            }
        }
    }

    fun register(context: Context, flutterEngine: FlutterEngine) {
        appContext = context.applicationContext
        audioManager = appContext?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
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
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> {
                        mixWithOthers = call.argument<Boolean>("mixWithOthers") ?: false
                        requestAudioFocus()
                        result.success(true)
                    }
                    "close" -> {
                        commitActiveSegment()
                        releaseRecorderOnly()
                        abandonAudioFocus()
                        mixWithOthers = false
                        isPaused = false
                        microphoneCaptureBlocked = false
                        resetDurationTracking()
                        result.success(null)
                    }
                    "start" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) false else startRecording(path))
                    }
                    "resumeSegment" -> result.success(resumeRecordingInternal())
                    "pauseSegment" -> result.success(pauseRecordingInternal())
                    "finish" -> {
                        val outputPath = call.argument<String>("outputPath")
                        result.success(if (outputPath.isNullOrBlank()) null else finish(outputPath))
                    }
                    "isRecording" -> result.success(isActivelyCapturing())
                    "currentPath" -> result.success(currentPath)
                    "fileSize" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) 0 else fileSize(path))
                    }
                    "segmentPaths" -> {
                        result.success(if (currentPath != null) listOf(currentPath) else emptyList<String>())
                    }
                    "currentDurationMs" -> result.success(currentRecordingDurationMs())
                    "isMicrophoneCaptureBlocked" -> result.success(isMicrophoneCaptureBlocked())
                    "prepareForRecordingResume" -> result.success(prepareForRecordingResume())
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** 混音模式申请焦点并监听恢复；来电/独占麦克风时 native 层同步 pause。 */
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
            val builder = AudioFocusRequest.Builder(focusGain)
                .setAudioAttributes(attrs)
                .setWillPauseWhenDucked(false)
            if (mixWithOthers) {
                builder.setOnAudioFocusChangeListener(focusChangeListener)
            }
            audioFocusRequest = builder.build()
            manager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            if (mixWithOthers) {
                manager.requestAudioFocus(
                    focusChangeListener,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
                )
            } else {
                @Suppress("DEPRECATION")
                manager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN,
                )
            }
        }
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { manager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(if (mixWithOthers) focusChangeListener else null)
        }
        audioFocusRequest = null
    }

    private fun isActivelyCapturing(): Boolean {
        return recorder != null && !isPaused
    }

    private fun startRecording(path: String): Boolean {
        if (currentPath == path && (recorder != null || accumulatedDurationMs > 0L)) {
            return if (isPaused) {
                resumeRecordingInternal()
            } else {
                false
            }
        }
        if (File(path).exists() && File(path).length() > 0L) {
            return false
        }
        commitActiveSegment()
        releaseRecorderOnly()
        resetDurationTracking()
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
            isPaused = false
            markActiveSegmentStarted()
            true
        } catch (_: Exception) {
            releaseRecorderOnly()
            false
        }
    }

    private fun releaseRecorderOnly() {
        commitActiveSegment()
        try {
            recorder?.stop()
        } catch (_: Exception) {
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
        isPaused = false
    }

    /** 暂停整段录音；API 24+ 使用 [MediaRecorder.pause]，低版本 stop 后无法续录。 */
    private fun pauseRecordingInternal(): String? {
        val path = currentPath ?: return null
        commitActiveSegment()
        val rec = recorder
        if (rec == null) {
            isPaused = true
            return path
        }
        if (isPaused) {
            return path
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                rec.pause()
            } catch (_: Exception) {
                // 系统可能已停止采集；保留 accumulatedDurationMs，仅标记暂停。
            }
            isPaused = true
            return path
        }
        releaseRecorderOnly()
        isPaused = true
        return path
    }

    /** 在同文件上继续录音；API 24+ 使用 [MediaRecorder.resume]（响应 App UI 或系统焦点恢复）。 */
    private fun resumeRecordingInternal(): Boolean {
        val rec = recorder ?: return false
        if (!isPaused) {
            return isActivelyCapturing()
        }
        prepareForRecordingResume()
        if (microphoneCaptureBlocked) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return try {
                rec.resume()
                isPaused = false
                markActiveSegmentStarted()
                true
            } catch (_: Exception) {
                false
            }
        }
        return false
    }

    /** 停止整段录音并返回最终文件路径。 */
    private fun finish(outputPath: String): String? {
        if (recorder != null) {
            if (isPaused && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    recorder?.resume()
                    isPaused = false
                } catch (_: Exception) {
                }
            }
            releaseRecorderOnly()
        }
        val path = currentPath ?: return null
        currentPath = null
        if (path == outputPath) {
            return path
        }
        File(outputPath).delete()
        return if (File(path).renameTo(File(outputPath))) {
            outputPath
        } else {
            path
        }
    }

    private fun fileSize(path: String): Int {
        return File(path).length().toInt()
    }

    private fun resetDurationTracking() {
        accumulatedDurationMs = 0
        activeSegmentStartedAtMs = null
    }

    private fun markActiveSegmentStarted() {
        activeSegmentStartedAtMs = SystemClock.elapsedRealtime()
    }

    /** 将当前连续录制段时长累加到 [accumulatedDurationMs]。 */
    private fun commitActiveSegment() {
        val startedAt = activeSegmentStartedAtMs ?: return
        if (recorder != null && !isPaused) {
            accumulatedDurationMs += (SystemClock.elapsedRealtime() - startedAt).coerceAtLeast(0)
        }
        activeSegmentStartedAtMs = null
    }

    /** 从已 finalize 文件读取时长；录制中通常返回 0。 */
    private fun readFileDurationMs(path: String): Long {
        val file = File(path)
        if (!file.exists() || file.length() <= 0L) {
            return 0L
        }
        return try {
            val retriever = android.media.MediaMetadataRetriever()
            retriever.setDataSource(path)
            val durationMs = retriever.extractMetadata(
                android.media.MediaMetadataRetriever.METADATA_KEY_DURATION,
            )?.toLongOrNull() ?: 0L
            retriever.release()
            durationMs.coerceAtLeast(0L)
        } catch (_: Exception) {
            0L
        }
    }

    /** 当前录音时长（毫秒）：录制中用 native 分段计时，有文件 metadata 时取较大值。 */
    private fun currentRecordingDurationMs(): Int {
        var tracked = accumulatedDurationMs
        if (recorder != null && !isPaused) {
            activeSegmentStartedAtMs?.let { startedAt ->
                tracked += (SystemClock.elapsedRealtime() - startedAt).coerceAtLeast(0)
            }
        }
        val path = currentPath
        if (path != null) {
            val fileDuration = readFileDurationMs(path)
            if (fileDuration > tracked) {
                tracked = fileDuration
            }
        }
        return tracked.toInt().coerceAtLeast(0)
    }

    /** 来电或独占麦克风场景下不可 start/resume。 */
    private fun isMicrophoneCaptureBlocked(): Boolean {
        refreshMicrophoneCaptureBlockedState()
        return microphoneCaptureBlocked
    }

    /** 根据当前 AudioManager 状态刷新占用标记，避免后台未收到 focus gain 时永久 blocked。 */
    private fun refreshMicrophoneCaptureBlockedState() {
        val manager = audioManager ?: return
        when (manager.mode) {
            AudioManager.MODE_IN_CALL, AudioManager.MODE_IN_COMMUNICATION -> {
                microphoneCaptureBlocked = true
            }
            else -> microphoneCaptureBlocked = false
        }
    }

    /** resume 前重新申请焦点并刷新占用状态。 */
    private fun prepareForRecordingResume(): Boolean {
        refreshMicrophoneCaptureBlockedState()
        requestAudioFocus()
        refreshMicrophoneCaptureBlockedState()
        return !microphoneCaptureBlocked
    }
}
