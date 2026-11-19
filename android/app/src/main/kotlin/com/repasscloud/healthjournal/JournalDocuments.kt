package com.repasscloud.healthjournal

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

internal class JournalDocuments(private val activity: Activity) {
    private sealed interface Request {
        val result: MethodChannel.Result

        data class Save(val bytes: ByteArray, override val result: MethodChannel.Result) : Request
        data class Open(override val result: MethodChannel.Result) : Request
    }

    private var pending: Request? = null

    fun saveCsv(bytes: ByteArray?, result: MethodChannel.Result) =
        save(bytes, result, "text/csv", "health-journal.csv")

    fun saveBackup(bytes: ByteArray?, result: MethodChannel.Result) =
        save(bytes, result, "application/octet-stream", "health-journal.healthbak")

    private fun save(
        bytes: ByteArray?, result: MethodChannel.Result, mimeType: String, name: String
    ) {
        if (bytes == null || bytes.isEmpty() || bytes.size > MAX_DOCUMENT_BYTES) {
            result.error("document_size", "File size is out of bounds.", null)
            return
        }
        launch(
            Request.Save(bytes, result),
            Intent(Intent.ACTION_CREATE_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType(mimeType)
                .putExtra(Intent.EXTRA_TITLE, name)
        )
    }

    fun openBackup(result: MethodChannel.Result) = launch(
        Request.Open(result),
        Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*")
    )

    @Suppress("DEPRECATION")
    private fun launch(request: Request, intent: Intent) {
        if (pending != null) {
            clear(request)
            request.result.error("document_pending", "A document request is already open.", null)
            return
        }
        pending = request
        try {
            activity.startActivityForResult(intent, DOCUMENT_REQUEST)
        } catch (_: Exception) {
            pending = null
            clear(request)
            request.result.error("document_picker", "The document picker is unavailable.", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != DOCUMENT_REQUEST) return false
        val request = pending ?: return true
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null) {
            pending = null
            clear(request)
            request.result.success(if (request is Request.Save) false else null)
            return true
        }
        Thread {
            try {
                val result = when (request) {
                    is Request.Save -> {
                        activity.contentResolver.openOutputStream(destination, "w")?.use {
                            it.write(request.bytes)
                        } ?: throw IllegalStateException("Document output is unavailable.")
                        true
                    }
                    is Request.Open -> read(destination)
                }
                activity.runOnUiThread {
                    pending = null
                    request.result.success(result)
                }
            } catch (_: Exception) {
                activity.runOnUiThread {
                    pending = null
                    request.result.error("document_io", "Could not access the selected document.", null)
                }
            } finally {
                clear(request)
            }
        }.start()
        return true
    }

    private fun read(uri: Uri): ByteArray {
        val input = activity.contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Document input is unavailable.")
        return input.use { stream ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val size = stream.read(buffer)
                if (size < 0) break
                if (output.size() + size > MAX_DOCUMENT_BYTES) {
                    throw IllegalArgumentException("Document exceeds the backup size limit.")
                }
                output.write(buffer, 0, size)
            }
            output.toByteArray()
        }
    }

    private fun clear(request: Request) {
        if (request is Request.Save) request.bytes.fill(0)
    }

    private companion object {
        const val DOCUMENT_REQUEST = 4802
        const val MAX_DOCUMENT_BYTES = 32 * 1024 * 1024 + 68
    }
}
