// android/app/src/main/kotlin/com/codemate/editor/UpdateService.kt
// 版本更新服务 - Android 原生实现

package com.codemate.editor

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.work.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class UpdateService(private val context: Context) {

    companion object {
        private const val TAG = "UpdateService"
        private const val CHANNEL_NAME = "com.codemate.update"
        private const val GITHUB_API_URL = "https://api.github.com/repos/vhqtvn/VHEditor-Android/releases"
        private const val CURRENT_VERSION = "2.22.0"
        
        private const val WORK_NAME_CHECK = "check_update"
        private const val WORK_NAME_DOWNLOAD = "download_update"
    }

    private var methodChannel: MethodChannel? = null
    private var downloadManager: DownloadManager? = null
    private var downloadReceiver: BroadcastReceiver? = null

    /**
     * 初始化
     */
    fun initialize(messenger: io.flutter.plugin.common.BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
        }

        downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        
        // 注册下载完成接收器
        registerDownloadReceiver()
        
        Log.d(TAG, "Update service initialized")
    }

    /**
     * 处理 MethodChannel 调用
     */
    private fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkForUpdate" -> {
                val silent = call.argument<Boolean>("silent") ?: false
                checkForUpdate(silent, result)
            }
            
            "downloadUpdate" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    downloadUpdate(url, result)
                } else {
                    result.error("INVALID_URL", "Download URL is required", null)
                }
            }
            
            "installUpdate" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    installUpdate(filePath, result)
                } else {
                    result.error("INVALID_PATH", "File path is required", null)
                }
            }
            
            "cancelDownload" -> {
                val taskId = call.argument<Long>("taskId")
                if (taskId != null) {
                    cancelDownload(taskId)
                    result.success(true)
                } else {
                    result.error("INVALID_TASK", "Task ID is required", null)
                }
            }
            
            "getCurrentVersion" -> {
                result.success(CURRENT_VERSION)
            }
            
            "schedulePeriodicCheck" -> {
                schedulePeriodicCheck()
                result.success(true)
            }
            
            else -> result.notImplemented()
        }
    }

    /**
     * 检查更新
     */
    private fun checkForUpdate(silent: Boolean, result: MethodChannel.Result) {
        Thread {
            try {
                if (!silent) {
                    sendStatus("checking", 0.0, null)
                }

                val response = fetchGitHubReleases()
                
                if (response != null) {
                    val latestVersion = response.getString("tag_name").removePrefix("v")
                    val downloadUrl = response.getJSONArray("assets")
                        .takeIf { it.length() > 0 }
                        ?.getJSONObject(0)
                        ?.getString("browser_download_url")
                    
                    val releaseNotes = response.getString("body")
                    val releaseDate = response.getString("published_at")
                    val isPrerelease = response.getBoolean("prerelease")
                    
                    val hasUpdate = compareVersions(latestVersion, CURRENT_VERSION) > 0

                    val updateInfo = JSONObject().apply {
                        put("hasUpdate", hasUpdate)
                        put("version", latestVersion)
                        put("currentVersion", CURRENT_VERSION)
                        put("downloadUrl", downloadUrl ?: "")
                        put("releaseNotes", releaseNotes)
                        put("releaseDate", releaseDate)
                        put("isPrerelease", isPrerelease)
                    }

                    sendStatus(
                        if (hasUpdate) "available" else "up_to_date",
                        0.0,
                        updateInfo
                    )
                    
                    result.success(updateInfo)
                } else {
                    sendError("无法获取更新信息")
                    result.error("FETCH_ERROR", "Failed to fetch releases", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking update", e)
                sendError(e.message ?: "Unknown error")
                result.error("CHECK_ERROR", e.message, null)
            }
        }.start()
    }

    /**
     * 获取 GitHub releases
     */
    private fun fetchGitHubReleases(): JSONObject? {
        return try {
            val url = URL(GITHUB_API_URL)
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept", "application/vnd.github+json")
            connection.setRequestProperty("User-Agent", "CodeMate-Android")
            connection.connectTimeout = 15000
            connection.readTimeout = 15000

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = reader.readText()
                reader.close()

                val releases = org.json.JSONArray(response)
                if (releases.length() > 0) {
                    releases.getJSONObject(0)
                } else {
                    null
                }
            } else {
                Log.e(TAG, "HTTP Error: ${connection.responseCode}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Network error", e)
            null
        }
    }

    /**
     * 比较版本号
     */
    private fun compareVersions(v1: String, v2: String): Int {
        val parts1 = v1.split(".").map { it.toIntOrNull() ?: 0 }
        val parts2 = v2.split(".").map { it.toIntOrNull() ?: 0 }

        for (i in 0 until maxOf(parts1.size, parts2.size)) {
            val p1 = parts1.getOrElse(i) { 0 }
            val p2 = parts2.getOrElse(i) { 0 }
            if (p1 != p2) return p1.compareTo(p2)
        }
        return 0
    }

    /**
     * 下载更新
     */
    private fun downloadUpdate(url: String, result: MethodChannel.Result) {
        try {
            val fileName = "CodeMate_${System.currentTimeMillis()}.apk"
            
            val request = DownloadManager.Request(Uri.parse(url)).apply {
                setTitle("CodeMate 更新")
                setDescription("正在下载新版本...")
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setDestinationInExternalPublicDir(android.os.Environment.DIRECTORY_DOWNLOADS, fileName)
                setAllowedOverMetered(true)
                setAllowedOverRoaming(false)
            }

            val downloadId = downloadManager?.enqueue(request)
            
            if (downloadId != null && downloadId > 0) {
                sendStatus("downloading", 0.0, JSONObject().apply {
                    put("taskId", downloadId)
                })
                result.success(mapOf(
                    "taskId" to downloadId,
                    "status" to "started"
                ))
            } else {
                result.error("DOWNLOAD_ERROR", "Failed to start download", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting download", e)
            result.error("DOWNLOAD_ERROR", e.message, null)
        }
    }

    /**
     * 安装更新
     */
    private fun installUpdate(filePath: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    // Android 7.0+ 需要 FileProvider
                    val apkUri = androidx.core.content.FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.fileprovider",
                        java.io.File(filePath)
                    )
                    setDataAndType(apkUri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    setDataAndType(Uri.fromFile(java.io.File(filePath)), "application/vnd.android.package-archive")
                }
            }
            
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error installing update", e)
            result.error("INSTALL_ERROR", e.message, null)
        }
    }

    /**
     * 取消下载
     */
    private fun cancelDownload(taskId: Long) {
        downloadManager?.remove(taskId)
    }

    /**
     * 注册下载完成接收器
     */
    private fun registerDownloadReceiver() {
        downloadReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val downloadId = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                if (downloadId != null && downloadId > 0) {
                    handleDownloadComplete(downloadId)
                }
            }
        }

        val filter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(downloadReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(downloadReceiver, filter)
        }
    }

    /**
     * 处理下载完成
     */
    private fun handleDownloadComplete(downloadId: Long) {
        val query = DownloadManager.Query().setFilterById(downloadId)
        val cursor = downloadManager?.query(query)
        
        cursor?.use {
            if (it.moveToFirst()) {
                val statusIndex = it.getColumnIndex(DownloadManager.COLUMN_STATUS)
                val localUriIndex = it.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)
                
                if (it.getInt(statusIndex) == DownloadManager.STATUS_SUCCESSFUL) {
                    val localUri = it.getString(localUriIndex)
                    
                    sendStatus("downloaded", 1.0, JSONObject().apply {
                        put("filePath", localUri?.removePrefix("file://"))
                    })
                }
            }
        }
    }

    /**
     * 计划定期检查
     */
    private fun schedulePeriodicCheck() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<CheckUpdateWorker>(
            24, TimeUnit.HOURS,
            1, TimeUnit.HOURS  // 弹性间隔
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME_CHECK,
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )

        Log.d(TAG, "Periodic check scheduled")
    }

    /**
     * 发送状态到 Flutter
     */
    private fun sendStatus(status: String, progress: Double, data: JSONObject?) {
        try {
            val payload = JSONObject().apply {
                put("status", status)
                put("progress", progress)
                put("data", data ?: JSONObject())
            }
            methodChannel?.invokeMethod("onStatusChanged", payload.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error sending status", e)
        }
    }

    /**
     * 发送错误
     */
    private fun sendError(message: String) {
        sendStatus("error", 0.0, JSONObject().apply {
            put("message", message)
        })
    }

    /**
     * 清理资源
     */
    fun dispose() {
        downloadReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                // Ignore
            }
        }
        downloadReceiver = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}

/**
 * 后台检查更新 Worker
 */
class CheckUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        // 实际实现应该在后台线程中检查更新
        // 如果有新版本，可以发送本地通知
        Log.d("CheckUpdateWorker", "Running periodic update check")
        return Result.success()
    }
}
