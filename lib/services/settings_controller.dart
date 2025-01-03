import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class SettingsController {
  static const platform = MethodChannel('com.ftrance.luna/settings');

  // Methods

  // Wifi
  Future<void> toggleWifi(bool enable) async {
    try {
      await platform.invokeMethod('toggleWifi', {'enable': enable});
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

  // AirplaneMode
  Future<void> toggleAirplaneMode(bool enable) async {
    try {
      await platform.invokeMethod('toggleAirplaneMode', {'enable': enable});
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
}
