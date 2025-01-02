package com.ftrance.luna

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity()
{
    override fun configureFlutterEngine(flutterEngine: FlutterEngine)
    {
        super.configureFlutterEngine(flutterEngine)
        // Register the settings manager
        flutterEngine.plugins.add(SettingsManager())
    }
}
