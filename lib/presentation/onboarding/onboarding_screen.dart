import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/onboarding/widgets/onboarding_container.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/presentation/onboarding/widgets/onboarding_appbar.dart';
import 'package:luna/presentation/onboarding/widgets/onboarding_items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = OnboardingItems();
  final _pageController = PageController();
  bool isLastPage = false;

  Future<void> setLogValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogged', true);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: SafeArea(child: OnboardingAppbar()),
      ),
      body: SafeArea(
        child: PageView.builder(
          onPageChanged: (index) {
            setState(() {
              isLastPage = index == _controller.items.length - 1;
            });
          },
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: _controller.items.length,
          itemBuilder: (BuildContext content, index) {
            setLogValue();
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    gradientColor,
                    primaryColor,
                  ],
                  stops: [0.0, 0.20],
                ),
              ),
              child: Column(
                children: [
                  // Image
                  Expanded(
                    flex: 5, // Adjust the flex value as needed
                    child: AspectRatio(
                      aspectRatio: 1.5, // Adjust the aspect ratio as needed
                      child: Image.asset(
                        _controller.items[index].image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: boxShadowColor,
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: OnBoardContainer(
                          pageController: _pageController,
                          controller: _controller,
                          title: _controller.items[index].title,
                          describtion: _controller.items[index].describtion,
                          buttonText: isLastPage ? 'Get Started' : 'Next',
                        ),
                      ),
                    ),
                  ),
                  kHeight20,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
