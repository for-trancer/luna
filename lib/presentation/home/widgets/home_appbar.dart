import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:flutter/services.dart';

class HomeAppbar extends StatelessWidget {
  const HomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: homeScreenFooter, // Set the status bar color to black
      statusBarIconBrightness:
          Brightness.light, // Dark icons for light status bar
    ));
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
          color: homeScreenFooter,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          )),
      // logo
      child: Image.asset(
        logoWhite,
        height: 50,
        width: 50,
      ),
    );
  }
}
