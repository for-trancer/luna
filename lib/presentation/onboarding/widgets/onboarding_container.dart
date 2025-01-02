import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/authentication/login_screen.dart';
import 'package:luna/presentation/home/home_screen.dart';
import 'package:luna/presentation/onboarding/widgets/onboarding_items.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardContainer extends StatelessWidget {
  const OnBoardContainer({
    super.key,
    required PageController pageController,
    required OnboardingItems controller,
    required this.title,
    required this.describtion,
    required this.buttonText,
  })  : _pageController = pageController,
        _controller = controller;

  final PageController _pageController;
  final OnboardingItems _controller;
  final String title;
  final String describtion;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        kHeight10,
        // smooth page indicator
        SmoothPageIndicator(
          controller: _pageController,
          count: _controller.items.length,
          onDotClicked: (index) => _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn),
          effect: const ScaleEffect(
            activeDotColor: secondaryColor,
            dotWidth: 5,
            dotHeight: 5,
          ),
        ),
        kHeight20,
        // title
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        kHeight20,
        // describtion
        Text(
          describtion,
          style: const TextStyle(
            fontSize: 16,
            color: primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        kHeight20,
        // OnBoardButton
        OnBoardButton(
          buttonText: buttonText,
          pageController: _pageController,
        ),
        kHeight20,
        // footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // login
            GestureDetector(
              onTap: () {
                // modalBottomSheet
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return LoginScreen();
                    });
              },
              child: const Row(
                children: [
                  Text('Already Have An Account? ',
                      style: TextStyle(
                        fontSize: 13,
                      )),
                  Text('Login',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        decoration: TextDecoration.underline,
                      )),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}

//OnBoardButton
class OnBoardButton extends StatelessWidget {
  const OnBoardButton({
    super.key,
    required PageController pageController,
    required this.buttonText,
  }) : _pageController = pageController;

  final PageController _pageController;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // check if end of onboarding page
      onPressed: () {
        if (buttonText == 'Get Started') {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => HomeScreen()));
        } else {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        minimumSize: const Size(250, 40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            buttonText,
            style: const TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(
            Icons.arrow_right,
            color: secondaryTextColor,
          )
        ],
      ),
    );
  }
}
