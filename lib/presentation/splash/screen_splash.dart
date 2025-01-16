import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/home/home_screen.dart';
import 'package:luna/presentation/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // timer
    Future.delayed(const Duration(seconds: 2), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) {
        bool? value = prefs.getBool('isLogged');
        if (value != null) {
          if (value) {
            return const HomeScreen();
          } else {
            return const OnboardingScreen();
          }
        } else {
          return const OnboardingScreen();
        }
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: primaryColor, // Set the status bar color to black
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for light status bar
    ));
    return Scaffold(
      body: Center(
        child: Image.asset(
          logoBlack,
          height: 250,
          width: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
