package ai.memopin.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 首页长录音：原生 MediaRecorder 整段写入单文件；混音模式，暂停/继续仅由 App UI 控制。
 */
object MPNativeRecorderPlugin {
    private const val CHANNEL = "mp_native_recorder"

    private var appContext: Context? = null
    private var methodChannel: MethodChannel? = null

    private var mixWithOthers = false
    private var recorder: MediaRecorder? = null
    private var currentPath: String? = null
    private var isPaused = false

    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    fun register(context: Context, flutterEngine: FlutterEngine) {
        appContext = context.applicationContext
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
                        isPaused = false
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
                    "isRecording" -> result.success(recorder != null && !isPaused)
                    "currentPath" -> result.success(currentPath)
                    "fileSize" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) 0 else fileSize(path))
                    }
                    "segmentPaths" -> {
                        result.success(if (currentPath != null) listOf(currentPath) else emptyList<String>())
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** 混音模式仅申请焦点，不监听变化以避免退后台/锁屏等自动暂停。 */
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
                .build()
            manager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                null,
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
            manager.abandonAudioFocus(null)
        }
        audioFocusRequest = null
    }

    private fun startRecording(path: String): Boolean {
        if (recorder != null && currentPath == path && isPaused) {
            return resumeRecordingInternal()
        }
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
            isPaused = false
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
        isPaused = false
    }

    /** 暂停整段录音；API 24+ 使用 [MediaRecorder.pause]，低版本 stop 后无法续录。 */
    private fun pauseRecordingInternal(): String? {
        val path = currentPath ?: return null
        val rec = recorder ?: return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                rec.pause()
                isPaused = true
                return path
            } catch (_: Exception) {
                return null
            }
        }
        releaseRecorderOnly()
        isPaused = true
        return path
    }

    /** 在同文件上继续录音；API 24+ 使用 [MediaRecorder.resume]（仅响应 App UI 调用）。 */
    private fun resumeRecordingInternal(): Boolean {
        val rec = recorder ?: return false
        if (!isPaused) {
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return try {
                rec.resume()
                isPaused = false
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
}
