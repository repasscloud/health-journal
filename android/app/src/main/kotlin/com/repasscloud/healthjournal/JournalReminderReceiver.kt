package com.repasscloud.healthjournal

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class JournalReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                val times = try {
                    if (enabled(context)) ReminderBootPlan(context).read(MAX_PENDING) else emptyList()
                } catch (_: Exception) {
                    emptyList()
                }
                replace(context, times)
            }
            DELIVER -> {
                if (enabled(context)) {
                    show(context, intent.getIntExtra("id", TEST_ID), false)
                } else {
                    replace(context, emptyList())
                }
            }
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                // A device-local slot calculated in the old zone is stale.
                // Recalculate with the loaded journal or on its next open.
                replace(context, emptyList())
                onClockChanged?.invoke()
            }
        }
    }

    companion object {
        // Set only while a production Flutter engine is attached. The
        // manifest receiver invalidates old alarms before requesting a plan.
        var onClockChanged: (() -> Unit)? = null

        private const val CHANNEL = "journal_reminders_v1"
        private const val DELIVER = "com.repasscloud.healthjournal.REMINDER"
        private const val FIRST_ID = 4000
        private const val MAX_PENDING = 64
        private const val TEST_ID = FIRST_ID + MAX_PENDING

        fun enabled(context: Context): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                return manager.getNotificationChannel(CHANNEL)?.importance !=
                    NotificationManager.IMPORTANCE_NONE
            }
            return true
        }

        fun replace(context: Context, times: List<Long>) {
            val alarms = context.getSystemService(AlarmManager::class.java)
            val notifications = context.getSystemService(NotificationManager::class.java)
            val flags = PendingIntent.FLAG_IMMUTABLE
            for (id in FIRST_ID until FIRST_ID + MAX_PENDING) {
                val pending = PendingIntent.getBroadcast(
                    context, id, delivery(context, id), flags or PendingIntent.FLAG_NO_CREATE
                )
                notifications.cancel(id)
                if (pending != null) {
                    alarms.cancel(pending)
                    pending.cancel()
                }
            }
            val allowed = enabled(context)
            if (!allowed) notifications.cancel(TEST_ID)
            val now = System.currentTimeMillis()
            val limit = now + 7L * 24 * 60 * 60 * 1000
            val future = if (allowed) {
                times.asSequence().filter { it in (now + 1)..limit }
                    .distinct().sorted().take(MAX_PENDING).toList()
            } else {
                emptyList()
            }
            try {
                ReminderBootPlan(context).write(future)
            } catch (_: Exception) {
                // A cache failure must not stop the foreground queue.
            }
            future.forEachIndexed { index, time ->
                val id = FIRST_ID + index
                val pending = PendingIntent.getBroadcast(
                    context, id, delivery(context, id), flags or PendingIntent.FLAG_UPDATE_CURRENT
                )
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, pending)
            }
        }

        private fun delivery(context: Context, id: Int) =
            Intent(context, JournalReminderReceiver::class.java)
                .setAction(DELIVER).putExtra("id", id)

        fun test(context: Context): Boolean = show(context, TEST_ID, true)

        private fun show(context: Context, id: Int, test: Boolean): Boolean {
            if (!enabled(context)) return false
            val manager = context.getSystemService(NotificationManager::class.java)
            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(NotificationChannel(
                    CHANNEL, "Journal reminders", NotificationManager.IMPORTANCE_DEFAULT
                ).apply { lockscreenVisibility = Notification.VISIBILITY_SECRET })
                Notification.Builder(context, CHANNEL)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            manager.notify(
                id, builder.setSmallIcon(android.R.drawable.ic_popup_reminder)
                    .setContentTitle("Health Journal")
                    .setContentText(if (test) "Test reminder" else "Open your journal to review a scheduled entry.")
                    .setVisibility(Notification.VISIBILITY_SECRET)
                    .setContentIntent(open)
                    .setAutoCancel(true)
                    .build()
            )
            return true
        }
    }
}
