package com.repasscloud.healthjournal

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.DataInputStream
import java.io.File
import java.nio.ByteBuffer
import java.security.KeyStore
import java.util.TimeZone
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** A bounded cache of notification times for same-zone, post-unlock reboot replay. */
internal class ReminderBootPlan(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "reminder-plan-v1"))
    private val store by lazy {
        KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    }

    fun clear() = file.delete()

    fun write(times: List<Long>) {
        clear()
        if (times.isEmpty()) return
        val key = readKey() ?: KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
        ).run {
            init(
                KeyGenParameterSpec.Builder(
                    KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setKeySize(256)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .build()
            )
            generateKey()
        }
        val zone = TimeZone.getDefault().id.toByteArray(Charsets.UTF_8)
        val clear = ByteBuffer.allocate(Int.SIZE_BYTES + zone.size + times.size * Long.SIZE_BYTES)
            .putInt(zone.size)
            .put(zone)
            .apply { times.forEach(::putLong) }
            .array()
        val cipher = Cipher.getInstance(CIPHER).apply { init(Cipher.ENCRYPT_MODE, key) }
        check(cipher.iv.size == IV_BYTES)
        val encrypted = try {
            cipher.iv + cipher.doFinal(clear)
        } finally {
            clear.fill(0)
        }
        val stream = file.startWrite()
        try {
            stream.write(encrypted)
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    fun read(maxTimes: Int): List<Long> {
        val key = readKey() ?: return emptyList()
        val encrypted = file.openRead().use { input ->
            val buffer = ByteArray(MAX_BYTES)
            DataInputStream(input).use { data ->
                val length = data.available()
                require(length in (IV_BYTES + TAG_BYTES + 1)..MAX_BYTES)
                data.readFully(buffer, 0, length)
                require(data.read() == -1)
                buffer.copyOf(length)
            }
        }
        val cipher = Cipher.getInstance(CIPHER).apply {
            init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_BYTES * 8, encrypted, 0, IV_BYTES))
        }
        val clear = cipher.doFinal(encrypted, IV_BYTES, encrypted.size - IV_BYTES)
        return try {
            val data = ByteBuffer.wrap(clear)
            val zoneLength = data.int
            require(zoneLength in 1..data.remaining())
            val zone = ByteArray(zoneLength).also { data.get(it) }
            if (zone.toString(Charsets.UTF_8) != TimeZone.getDefault().id) return emptyList()
            val count = data.remaining() / Long.SIZE_BYTES
            require(count in 1..maxTimes && data.remaining() == count * Long.SIZE_BYTES)
            List(count) { data.long }
        } finally {
            clear.fill(0)
        }
    }

    private fun readKey(): SecretKey? = store.getKey(KEY_ALIAS, null) as? SecretKey

    private companion object {
        const val KEY_ALIAS = "health_journal.reminder_plan.v1"
        const val CIPHER = "AES/GCM/NoPadding"
        const val IV_BYTES = 12
        const val TAG_BYTES = 16
        const val MAX_BYTES = 1024
    }
}
