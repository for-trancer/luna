import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/onboarding/widgets/onboarding_info.dart';

class OnboardingItems {
  List<OnboardingInfo> items = [
    const OnboardingInfo(
        title: 'Meet Luna',
        describtion:
            'Your Intelligent Voice Assistant, simplifying your daily routines with seamless voice interactions. Ask Luna anything and unlock a world of possibilities at your fingertips',
        image: assistantGif),
    const OnboardingInfo(
        title: 'Image Generation',
        describtion:
            'Transform your ideas into stunning visuals with AI Image Generation. Create high-quality, custom images quickly and effortlessly',
        image: imageGif),
    const OnboardingInfo(
        title: 'Seamless Offline Capabilities',
        describtion:
            'Unlock basic offline functionalities, like managing phone settings',
        image: offlineGif),
    const OnboardingInfo(
        title: 'Information Insights',
        describtion:
            'Leverage the OpenAI feature for instant access to valuable information and knowledge.',
        image: chatGptGif),
  ];
}
