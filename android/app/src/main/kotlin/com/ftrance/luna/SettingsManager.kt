package com.ftrance.luna

import com.ftrance.luna.AlarmReceiver
import android.util.Log
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.net.wifi.WifiManager
import android.provider.Settings
import android.bluetooth.BluetoothAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.content.ComponentName
import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.media.RingtoneManager
import android.media.Ringtone
import android.os.Build
import java.util.*
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.widget.Toast 

class SettingsManager: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext // Get the application context
        channel = MethodChannel(binding.binaryMessenger, "com.ftrance.luna/settings")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        when (call.method) {

            "toggleWiFi" -> {
                toggleWiFi()
                result.success(null)
            }

            "toggleBluetooth" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                toggleBluetooth(enable)
                result.success(null)
            }

            "toggleAudioMute" -> {
                val enable = call.argument<Boolean>("enable")?: false
                toggleAudioMute(enable)
                result.success(null)
            }

            "toggleAudioFull" -> {
                toggleAudioFull()
                result.success(null)
            }

            "toggleAudioDown" -> {
                toggleAudioDown()
                result.success(null)
            }

            "toggleHotspot" -> {
                toggleHotspot()
                result.success(null)
            }

            "setAlarm" -> {
                val year = call.argument<Int>("year") ?: 0
                val month = call.argument<Int>("month") ?: 0
                val day = call.argument<Int>("day") ?: 0
                val hour = call.argument<Int>("hour") ?: 0
                val minute = call.argument<Int>("minute") ?: 0
                setAlarm(year, month, day, hour, minute) 
                result.success(null)
            }

            "setReminder" -> {
                val year = call.argument<Int>("year") ?: 0
                val month = call.argument<Int>("month") ?: 0
                val day = call.argument<Int>("day") ?: 0
                val hour = call.argument<Int>("hour") ?: 0
                val minute = call.argument<Int>("minute") ?: 0
                val title = call.argument<String>("title") ?: "Reminder"
                setReminder(year,month,day,hour,minute,title)
                result.success(null)
            }

            "openApp" -> {
                val packageName = call.argument<String>("packageName")?: ""
                openApp(packageName)
                result.success(null)
            }

            "playYoutube" -> {
                val searchText = call.argument<String>("searchText") ?: ""
                playYoutube(searchText)
                result.success(null)
            }

            "toggleAlarmOff" -> {
                val year = call.argument<Int>("year") ?: 0
                val month = call.argument<Int>("month") ?: 0
                val day = call.argument<Int>("day") ?: 0
                val hour = call.argument<Int>("hour") ?: 0
                val minute = call.argument<Int>("minute") ?: 0
                toggleAlarmOff(year, month, day, hour, minute) 
                result.success(null)
            }

            "openMobileDataSettings" -> {
                openMobileDataSettings()
                result.success(null)
            }

            "increaseBrightness" -> {
                increaseBrightness()
                result.success(null)
            }

            "decreaseBrightness" -> {
                decreaseBrightness()
                result.success(null)
            }

            "setMaxBrightness" -> {
                setMaxBrightness()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // Wifi
    private fun toggleWiFi() {
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        Log.d("WiFiToggle", "Opened WiFi settings for user to manually toggle WiFi.")
    }

    // Bluetooth
    private fun toggleBluetooth(enable: Boolean) {
        val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null) {
            if (enable) {
                if (!bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.enable() // Turn on Bluetooth
                    Log.d("Error","Bluetooth is enabled.")
                } else {
                    Log.d("Error","Bluetooth is already enabled.")
                }
            } else {
                if (bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.disable() // Turn off Bluetooth
                    Log.d("Error","Bluetooth is disabled.")
                } else {
                    Log.d("Error","Bluetooth is already disabled.")
                }
            }
        } else {
            Log.d("Error","Bluetooth is not supported on this device.")
        }
    }

    // Audio Mute
    private fun toggleAudioMute(enable: Boolean) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (enable) {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0) // Mute
            Log.d("SettingsManager", "Audio is muted.")
        } else {
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(maxVolume / 2, 0,0) 
            Log.d("SettingsManager", "Audio is unmuted.")
        }
    }

    // Audio Full
    private fun toggleAudioFull() {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0) // Ensure valid stream type
        Log.d("SettingsManager", "Audio is set to full volume. Max Volume: $maxVolume")
    }

    // Audio Volume Down
    private fun toggleAudioDown() {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val newVolume = (currentVolume - 2).coerceAtLeast(0) // Ensure volume doesn't go below 0
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, newVolume, 0) // Set the new volume
        Log.d("SettingsManager", "Volume decreased to: $newVolume")
    }

    // Hotspot 
    private fun toggleHotspot() {
        // Create an intent to open the tethering settings
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
            component = ComponentName("com.android.settings", "com.android.settings.TetherSettings")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
    
        // Try to start the activity
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e("SettingsManager", "Failed to open hotspot settings: ${e.message}")
        }
    }

    // Set Alarm
    private fun setAlarm(year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        Log.d("SettingsManager", "setAlarm called with: $year-$month-$day $hour:$minute")
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java) // Create an Intent for the AlarmReceiver
        val pendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)

        val calendar = Calendar.getInstance().apply {
            set(year, month - 1, day, hour, minute, 0) // Month is 0-based in Calendar
            set(Calendar.SECOND, 0)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }

        Log.d("SettingsManager", "Alarm set for: $year-$month-$day $hour:$minute")
    }

    // Set Reminder
    private fun setReminder(year: Int, month: Int, day: Int, hour: Int, minute: Int, title: String) {
        Log.d("SettingsManager", "setReminder called with: $year-$month-$day $hour:$minute, Title: $title")
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("title", title) 
        }
        val pendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)

        val calendar = Calendar.getInstance().apply {
            set(year, month - 1, day, hour, minute, 0) // Month is 0-based in Calendar
            set(Calendar.SECOND, 0)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }

        Log.d("SettingsManager", "Reminder set for: $year-$month-$day $hour:$minute with title: $title")
    }

    // Alarm Off
    private fun toggleAlarmOff(year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java) // Create an Intent for the AlarmReceiver
        val pendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)

        // Remove The Alarm
        alarmManager.cancel(pendingIntent)

        Log.d("SettingsManager", "Alarm set for: $year-$month-$day $hour:$minute")
    }

    // Open App
    private fun openApp(packageName: String){
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            // Set the FLAG_ACTIVITY_NEW_TASK flag
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } else {
            // Handle the case where the app is not installed
            val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
            marketIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) // Also set the flag for the market intent
            context.startActivity(marketIntent)
        }
    }

    // Youtube
    private fun playYoutube(searchText: String) {
        val searchUrl = "https://www.youtube.com/results?search_query=${Uri.encode(searchText)}"
        
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(searchUrl))
        
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        
        context.startActivity(intent)
    }

    // Mobile Data
    fun openMobileDataSettings() {
        val intent = Intent(Settings.ACTION_DATA_ROAMING_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        Log.d("Settings", "Opened mobile data settings for user to manually toggle mobile data.")
    }

    private val BRIGHTNESS_STEP = 0.25f

    // Increase Brightness
    private fun increaseBrightness() {
        if (Settings.System.canWrite(context)) {
            val currentBrightness = Settings.System.getInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 0)
            val delta = (BRIGHTNESS_STEP * 255).toInt()  
            val newBrightness = (currentBrightness + delta).coerceIn(0, 255)
            Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, newBrightness)
            Log.d("SettingsManager", "Brightness increased to: $newBrightness")
        } else {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
            intent.data = Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            Toast.makeText(context, "Please allow permission to change brightness", Toast.LENGTH_SHORT).show()
        }
    }

    // Decrease Brightness
    private fun decreaseBrightness() {
        if (Settings.System.canWrite(context)) {
            val currentBrightness = Settings.System.getInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 0)
            val delta = (BRIGHTNESS_STEP * 255).toInt()
            val newBrightness = (currentBrightness - delta).coerceIn(0, 255)
            Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, newBrightness)
            Log.d("SettingsManager", "Brightness decreased to: $newBrightness")
        } else {
             val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
             intent.data = Uri.parse("package:${context.packageName}")
             intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
             context.startActivity(intent)
             Toast.makeText(context, "Please allow permission to change brightness", Toast.LENGTH_SHORT).show()
        }
    }

    // Maximum Brightness
    private fun setMaxBrightness() {
        if (Settings.System.canWrite(context)) {
            Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 255)
            Log.d("SettingsManager", "Brightness set to maximum.")
        } else {
             val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
             intent.data = Uri.parse("package:${context.packageName}")
             intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
             context.startActivity(intent)
             Toast.makeText(context, "Please allow permission to change brightness", Toast.LENGTH_SHORT).show()
        }
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}