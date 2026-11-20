package com.repasscloud.healthjournal

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

internal class JournalDocuments(private val activity: Activity) {
    private sealed interface Request {
        val result: MethodChannel.Result

        data class Save(val bytes: ByteArray, override val result: MethodChannel.Result) : Request
        data class Open(override val result: MethodChannel.Result) : Request
    }

    private var pending: Request? = null

    fun saveCsv(bytes: ByteArray?, result: MethodChannel.Result) =
        save(bytes, result, "text/csv", "health-journal.csv")

    fun savePdf(bytes: ByteArray?, result: MethodChannel.Result) =
        save(bytes, result, "application/pdf", REPORT_NAME)

    fun removeInterruptedShares() {
        // Retain a grant if Android recreated the Activity in the same process.
        shareDirectory.listFiles()?.filterNot { it in activeShares }?.forEach { it.delete() }
    }

    fun sharePdf(bytes: ByteArray?, result: MethodChannel.Result) {
        if (bytes == null || bytes.isEmpty() || bytes.size > MAX_DOCUMENT_BYTES) {
            bytes?.fill(0)
            result.error("document_size", "File size is out of bounds.", null)
            return
        }
        // Keep one bounded share at a time. Existing recipients retain their
        // open file descriptors if a subsequent share replaces the grant.
        activeShares.toList().forEach { discardShare(it, uriFor(it)) }
        var file: File? = null
        var uri: Uri? = null
        try {
            check(shareDirectory.isDirectory || shareDirectory.mkdir())
            file = File.createTempFile("journal-", ".pdf", shareDirectory)
            file.writeBytes(bytes)
            uri = uriFor(file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri(REPORT_NAME, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            activity.startActivity(Intent.createChooser(intent, null))
            activeShares.add(file)
            val sharedFile = file
            val sharedUri = uri
            Handler(Looper.getMainLooper()).postDelayed(
                { discardShare(sharedFile, sharedUri) },
                SHARE_LIFETIME_MS
            )
            result.success(true)
        } catch (_: Exception) {
            if (file != null) discardShare(file, uri)
            result.error("document_share", "The PDF could not be shared.", null)
        } finally {
            bytes.fill(0)
        }
    }

    private val shareDirectory get() = File(activity.cacheDir, "shared-reports")

    private fun uriFor(file: File): Uri = FileProvider.getUriForFile(
        activity, "${activity.packageName}.reports", file, REPORT_NAME
    )

    private fun discardShare(file: File, uri: Uri?) {
        try {
            if (uri != null) activity.revokeUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } finally {
            file.delete()
            activeShares.remove(file)
        }
    }

    fun saveBackup(bytes: ByteArray?, result: MethodChannel.Result) =
        save(bytes, result, "application/octet-stream", "health-journal.healthbak")

    private fun save(
        bytes: ByteArray?, result: MethodChannel.Result, mimeType: String, name: String
    ) {
        if (bytes == null || bytes.isEmpty() || bytes.size > MAX_DOCUMENT_BYTES) {
            bytes?.fill(0)
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
        val activeShares = mutableSetOf<File>()
        const val REPORT_NAME = "health-journal-report.pdf"
        const val SHARE_LIFETIME_MS = 10 * 60 * 1000L
        const val DOCUMENT_REQUEST = 4802
        const val MAX_DOCUMENT_BYTES = 32 * 1024 * 1024 + 68
    }
}
