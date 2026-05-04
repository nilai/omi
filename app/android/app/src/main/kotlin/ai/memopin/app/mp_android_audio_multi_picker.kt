package ai.memopin.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream

/**
 * 使用 [Intent.ACTION_GET_CONTENT] + [Intent.EXTRA_ALLOW_MULTIPLE] 打开系统选择器，
 * 避免部分 ROM 上 [Intent.ACTION_OPEN_DOCUMENT]（file_picker 默认）忽略多选的问题。
 */
object MpAndroidAudioMultiPicker {
    private const val CHANNEL = "ai.memopin.app/mp_android_audio_multi_picker"
    private const val REQUEST_CODE = 99107

    private var pendingResult: MethodChannel.Result? = null

    fun register(activity: Activity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "pickMultipleAudio") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingResult != null) {
                result.error("already_active", "Picker already active", null)
                return@setMethodCallHandler
            }
            pendingResult = result
            val title = call.argument<String>("title") ?: "选择音频文件"
            launchPicker(activity, title)
        }
    }

    fun handleActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }
        val pending = pendingResult
        pendingResult = null
        if (pending == null) {
            return true
        }
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending.success(emptyList<String>())
            return true
        }
        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let { uris.add(it) }
            }
        }
        if (uris.isEmpty()) {
            data.data?.let { uris.add(it) }
        }
        Thread {
            val paths = ArrayList<String>(uris.size)
            for (uri in uris) {
                copyUriToCache(activity, uri)?.let { paths.add(it) }
            }
            activity.runOnUiThread {
                pending.success(paths)
            }
        }.start()
        return true
    }

    private fun launchPicker(activity: Activity, title: String) {
        val intent = buildPickIntent()
        try {
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivityForResult(intent, REQUEST_CODE)
                return
            }
        } catch (_: Exception) {
            /* fall through to chooser */
        }
        try {
            activity.startActivityForResult(Intent.createChooser(buildPickIntent(), title), REQUEST_CODE)
        } catch (e: Exception) {
            pendingResult?.error("launch_failed", e.message, null)
            pendingResult = null
        }
    }

    private fun buildPickIntent(): Intent {
        val mimeTypes = arrayOf(
            "audio/mpeg",
            "audio/mp4",
            "audio/x-m4a",
            "audio/wav",
            "audio/x-wav",
            "audio/flac",
            "audio/ogg",
            "audio/opus",
            "audio/aac",
            "audio/x-aac",
            "application/ogg",
        )
        return Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
    }

    private fun copyUriToCache(activity: Activity, uri: Uri): String? {
        return try {
            val rawName = queryDisplayName(activity, uri) ?: "audio_${System.currentTimeMillis()}"
            val safeName = rawName.replace("/", "_")
            val dir = File(activity.cacheDir, "mp_audio_pick/${System.currentTimeMillis()}")
            dir.mkdirs()
            val outFile = File(dir, safeName)
            activity.contentResolver.openInputStream(uri)?.use { input ->
                BufferedInputStream(input).use { bin ->
                    BufferedOutputStream(FileOutputStream(outFile)).use { bout ->
                        bin.copyTo(bout)
                    }
                }
            } ?: return null
            outFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun queryDisplayName(activity: Activity, uri: Uri): String? {
        if (uri.scheme != "content") {
            return uri.lastPathSegment
        }
        var cursor: android.database.Cursor? = null
        try {
            cursor = activity.contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
            if (cursor != null && cursor.moveToFirst()) {
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) {
                    return cursor.getString(idx)
                }
            }
        } finally {
            cursor?.close()
        }
        return null
    }
}
