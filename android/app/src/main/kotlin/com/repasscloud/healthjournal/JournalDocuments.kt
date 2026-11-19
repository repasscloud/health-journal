package com.repasscloud.healthjournal

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

internal class JournalDocuments(private val activity: Activity) {
    private data class Save(val bytes: ByteArray, val result: MethodChannel.Result)
    private var pending: Save? = null

    @Suppress("DEPRECATION")
    fun saveCsv(bytes: ByteArray?, result: MethodChannel.Result) {
        if (bytes == null || bytes.isEmpty() || bytes.size > 32 * 1024 * 1024) {
            result.error("document_size", "CSV file size is out of bounds.", null)
            return
        }
        if (pending != null) {
            result.error("document_pending", "A save request is already open.", null)
            return
        }
        pending = Save(bytes, result)
        try {
            activity.startActivityForResult(
                Intent(Intent.ACTION_CREATE_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("text/csv")
                    .putExtra(Intent.EXTRA_TITLE, "health-journal.csv"),
                SAVE_REQUEST
            )
        } catch (_: Exception) {
            pending = null
            bytes.fill(0)
            result.error("document_picker", "The document picker is unavailable.", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_REQUEST) return false
        val save = pending ?: return true
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null) {
            pending = null
            save.bytes.fill(0)
            save.result.success(false)
            return true
        }
        Thread {
            val success = try {
                activity.contentResolver.openOutputStream(destination, "w")?.use {
                    it.write(save.bytes)
                } ?: throw IllegalStateException("Document output is unavailable.")
                true
            } catch (_: Exception) {
                false
            } finally {
                save.bytes.fill(0)
            }
            activity.runOnUiThread {
                pending = null
                if (success) save.result.success(true)
                else save.result.error("document_write", "Could not write the selected document.", null)
            }
        }.start()
        return true
    }

    private companion object {
        const val SAVE_REQUEST = 4802
    }
}
