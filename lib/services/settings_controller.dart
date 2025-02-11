import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

class SettingsController {
  static const platform = MethodChannel('com.ftrance.luna/settings');

  // Methods

  // Wifi
  Future<void> toggleWifi() async {
    try {
      await platform.invokeMethod('toggleWiFi');
    } on PlatformException catch (e) {
      log("failed to toggle wifi: ${e.message}");
    }
  }

  // Bluetooth
  Future<void> toggleBluetooth(bool enable) async {
    try {
      await platform.invokeMethod('toggleBluetooth', {'enable': enable});
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Audio Mute
  Future<void> toggleAudioMute(bool enable) async {
    try {
      await platform.invokeListMethod('toggleAudioMute', {'enable': enable});
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Audio Full
  Future<void> toggleAudioFull() async {
    try {
      await platform.invokeMethod('toggleAudioFull');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Audio Down
  Future<void> toggleAudioDown() async {
    try {
      await platform.invokeMethod('toggleAudioDown');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Hotspot
  Future<void> toggleHotspot() async {
    try {
      await platform.invokeMethod('toggleHotspot');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Alarm
  Future<void> toggleAlarm(
      int year, int month, int day, int hour, int minute) async {
    try {
      await platform.invokeMethod('setAlarm', {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute
      });
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Remove Alarm
  void toggleAlarmOff() {
    try {
      platform.invokeMethod('toggleAlarmOff');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Open App
  Future<void> openApp(String packageName) async {
    try {
      await platform.invokeMethod('openApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Youtube
  Future<void> playYoutube(String searchText) async {
    try {
      await platform.invokeMethod('playYoutube', {'searchText': searchText});
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Reminder
  Future<void> setReminder(
      int year, int month, int day, int hour, int minute, String title) async {
    try {
      await platform.invokeMethod('setReminder', {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'title': title,
      });
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Mobile Data
  Future<void> openMobileDataSettings() async {
    try {
      await platform.invokeMethod('openMobileDataSettings');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Increase Brightness
  Future<void> increaseBrightness() async {
    try {
      await platform.invokeMethod('increaseBrightness');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Increase Brightness
  Future<void> decreaseBrightness() async {
    try {
      await platform.invokeMethod('decreaseBrightness');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }

  // Increase Brightness
  Future<void> setMaxBrightness() async {
    try {
      await platform.invokeMethod('setMaxBrightness');
    } on PlatformException catch (e) {
      log(e.message!);
    }
  }
}
