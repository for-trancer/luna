import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:luna/presentation/splash/screen_splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna',
      theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: primaryColor,
          fontFamily: 'Poppins'),
      home: const SplashScreen(),
    );
  }
}
