package com.repasscloud.healthjournal

import android.app.Activity
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey

internal class JournalBiometrics(private val activity: Activity) {
    private val preferences get() = activity.getSharedPreferences("journal_biometrics", 0)
    private val store get() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private var pending: CancellationSignal? = null
    private var reply: MethodChannel.Result? = null

    fun handle(method: String, result: MethodChannel.Result) {
        try {
            when (method) {
                "status" -> result.success(mapOf(
                    "available" to available(),
                    "enabled" to preferences.getBoolean(ENABLED, false)
                ))
                "disable" -> {
                    disable()
                    result.success(true)
                }
                "enable", "authenticate" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                        result.success(false)
                        return
                    }
                    prompt(method == "enable", result)
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            if (reply == result) {
                finish(false)
            } else {
                result.error("biometrics_unavailable", "Android biometric access is unavailable.", null)
            }
        }
    }

    fun cancel() {
        val signal = pending
        finish(false)
        signal?.cancel()
    }

    private fun available(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            activity.getSystemService(BiometricManager::class.java)
                .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) ==
            BiometricManager.BIOMETRIC_SUCCESS

    private fun disable() {
        check(preferences.edit().remove(ENABLED).commit())
        store.deleteEntry(ALIAS)
    }

    @android.annotation.TargetApi(Build.VERSION_CODES.R)
    private fun prompt(enroll: Boolean, result: MethodChannel.Result) {
        if (reply != null || !available() ||
            (!enroll && !preferences.getBoolean(ENABLED, false))) {
            result.success(false)
            return
        }
        val key = if (enroll) {
            disable()
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, "AndroidKeyStore").run {
                init(
                    KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                        .setUserAuthenticationRequired(true)
                        .setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                        .setInvalidatedByBiometricEnrollment(true)
                        .build()
                )
                generateKey()
            }
        } else {
            store.getKey(ALIAS, null) as? SecretKey
        }
        if (key == null) {
            disable()
            result.success(false)
            return
        }
        val mac = Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256)
        try {
            mac.init(key)
        } catch (_: KeyPermanentlyInvalidatedException) {
            disable()
            result.success(false)
            return
        }

        val signal = CancellationSignal()
        val executor = activity.mainExecutor
        pending = signal
        reply = result
        BiometricPrompt.Builder(activity)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .setTitle(if (enroll) "Enable biometric unlock" else "Unlock Health Journal")
            .setNegativeButton("Use journal PIN", executor) { _, _ ->
                if (pending === signal) finish(false)
            }
            .build()
            .authenticate(
                BiometricPrompt.CryptoObject(mac), signal, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        if (pending === signal) finish(false)
                    }

                    override fun onAuthenticationSucceeded(auth: BiometricPrompt.AuthenticationResult) {
                        if (pending !== signal) return
                        val verified = try {
                            val proof = auth.cryptoObject?.mac?.doFinal(byteArrayOf(1))
                            proof?.fill(0)
                            proof != null && (!enroll || preferences.edit().putBoolean(ENABLED, true).commit())
                        } catch (_: Exception) {
                            false
                        }
                        finish(verified)
                    }
                }
            )
    }

    private fun finish(verified: Boolean) {
        val result = reply
        pending = null
        reply = null
        result?.success(verified)
    }

    private companion object {
        const val ALIAS = "health_journal.biometric_unlock.v1"
        const val ENABLED = "enabled"
    }
}
