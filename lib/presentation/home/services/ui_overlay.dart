import 'package:flutter/services.dart';
import 'package:luna/core/colors/colors.dart';

void setUiOverlay() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: homeScreenFooter, // Set the status bar color to black
    statusBarIconBrightness:
        Brightness.light, // Dark icons for light status bar
  ));
}
