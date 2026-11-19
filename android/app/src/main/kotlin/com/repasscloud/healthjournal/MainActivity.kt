package com.repasscloud.healthjournal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterActivity() {
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
