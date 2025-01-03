package com.ftrance.luna

import android.util.Log
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.provider.Settings
import android.bluetooth.BluetoothAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.content.ComponentName

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
                val enable = call.argument<Boolean>("enable") ?: false
                toggleWiFi(enable)
                result.success(null)
            }

            "toggleBluetooth" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                toggleBluetooth(enable)
                result.success(null)
            }

            "toggleAirplaneMode" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                toggleAirplaneMode(enable)
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

            else -> result.notImplemented()
        }
    }

    // Wifi
    private fun toggleWiFi(enable: Boolean) {
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (enable != wifiManager.isWifiEnabled) {
            wifiManager.isWifiEnabled = enable
        }
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

    // Airplane
    private fun toggleAirplaneMode(enable: Boolean) {
        Settings.Global.putInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, if (enable) 1 else 0)
        val intent = Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED)
        intent.putExtra("state", enable)
        context.sendBroadcast(intent)
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


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}