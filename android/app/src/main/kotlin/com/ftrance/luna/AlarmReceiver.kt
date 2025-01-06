package com.ftrance.luna

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

// Singleton object to hold the ringtone reference
object RingtoneHolder {
    var ringtone: Ringtone? = null
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Handle the alarm trigger here
        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        RingtoneHolder.ringtone = RingtoneManager.getRingtone(context, ringtoneUri)
        RingtoneHolder.ringtone?.play()

        Log.d("AlarmReceiver", "Alarm triggered!")

        // Create a notification
        val notificationId = 1
        val channelId = "alarm_channel"
        val channelName = "Alarm Notifications"

        // Create a notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }

        // Create an intent to dismiss the notification
        val dismissIntent = Intent(context, DismissReceiver::class.java)
        // Use FLAG_IMMUTABLE when creating the PendingIntent
        val dismissPendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build the notification
        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // Using a default system icon
            .setContentTitle("Alarm Triggered")
            .setContentText("Your alarm is ringing!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPendingIntent) // Dismiss action

        // Show the notification
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.notify(notificationId, notificationBuilder.build())
    }
}

// Create a separate BroadcastReceiver to handle the dismiss action
class DismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Handle the dismiss action here
        Log.d("DismissReceiver", "Alarm dismissed!")
        
        // Stop the ringtone if it's playing
        RingtoneHolder.ringtone?.stop()
        RingtoneHolder.ringtone = null // Clear the reference
    }
}