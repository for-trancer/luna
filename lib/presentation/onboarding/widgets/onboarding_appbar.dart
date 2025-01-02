import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/home/home_screen.dart';

class OnboardingAppbar extends StatelessWidget {
  const OnboardingAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Image.asset(
            logoBlack,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
          // App Bar Button
          const OnBoardAppBarButton(text: 'Skip')
        ],
      ),
    );
  }
}

class OnBoardAppBarButton extends StatelessWidget {
  final String text;
  const OnBoardAppBarButton({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // skip button
    return ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => HomeScreen()));
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            side: const BorderSide(color: primaryTextColor, width: 2.0)),
        child: Text(
          text,
          style: const TextStyle(color: primaryTextColor),
        ));
  }
}
