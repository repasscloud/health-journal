package com.repasscloud.healthjournal

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val documents = JournalDocuments(this)

    @Deprecated("Deprecated in the Android Activity API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!documents.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private var notificationRequest: MethodChannel.Result? = null

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4801) {
            notificationRequest?.success(JournalReminderReceiver.enabled(this))
            notificationRequest = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (BuildConfig.FLAVOR == "production") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                setRecentsScreenshotEnabled(false)
            } else {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "health_journal/device_time_zone").setMethodCallHandler { call, result ->
            if (call.method == "read") {
                result.success(TimeZone.getDefault().id)
            } else {
                result.notImplemented()
            }
        }
        // Fictional review uses volatile data. Do not register
        // storage/key plugins or the protected-directory channel for this flavor.
        if (BuildConfig.FLAVOR == "review") return
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "health_journal/documents").setMethodCallHandler { call, result ->
            when (call.method) {
                "saveCsv" -> documents.saveCsv(call.arguments as? ByteArray, result)
                "saveBackup" -> documents.saveBackup(call.arguments as? ByteArray, result)
                "openBackup" -> documents.openBackup(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "health_journal/reminders").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "enabled" -> result.success(JournalReminderReceiver.enabled(this))
                    "test" -> result.success(JournalReminderReceiver.test(this))
                    "replace" -> {
                        val times = call.arguments as? List<*> ?: emptyList<Any>()
                        JournalReminderReceiver.replace(this, times.mapNotNull { (it as? Number)?.toLong() })
                        result.success(null)
                    }
                    "request" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                            result.success(JournalReminderReceiver.enabled(this))
                        } else if (notificationRequest != null) {
                            result.error("permission_pending", "A permission request is already open.", null)
                        } else {
                            notificationRequest = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4801)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                if (notificationRequest == result) notificationRequest = null
                result.error("reminders_unavailable", "Reminders could not be updated.", null)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "health_journal/private_store").setMethodCallHandler { call, result ->
            if (call.method != "prepare") {
                result.notImplemented()
            } else {
                val directory = File(noBackupFilesDir, "protected_journal")
                if ((directory.isDirectory || directory.mkdirs()) &&
                    directory.setReadable(false, false) &&
                    directory.setWritable(false, false) &&
                    directory.setExecutable(false, false) &&
                    directory.setReadable(true, true) &&
                    directory.setWritable(true, true) &&
                    directory.setExecutable(true, true)) {
                    result.success(directory.absolutePath)
                } else {
                    result.error("protected_storage_unavailable",
                        "Protected storage could not be prepared.", null)
                }
            }
        }
    }
}
