import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/home/services/home_service.dart'; // Import the new service
import 'package:luna/presentation/home/services/ui_overlay.dart';
import 'package:luna/presentation/home/widgets/home_appbar.dart';
import 'package:luna/presentation/home/widgets/image_response_widget.dart';
import 'package:luna/presentation/home/widgets/type_writer_text.dart';
import 'package:luna/presentation/home/widgets/voice_record_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final HomeService _homeService = HomeService();

  @override
  void initState() {
    super.initState();
    _homeService.initSpeechTts();
  }

  @override
  Widget build(BuildContext context) {
    // ui overlay
    setUiOverlay();

    // say greetings
    // _homeService.sayGreetings();

    double size = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: SafeArea(
          // App Bar
          child: HomeAppbar(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(30),
                height: 600,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: homeScreenBorderColor,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: ValueListenableBuilder(
                    valueListenable: _homeService.isImageNotifier,
                    builder: (BuildContext context, bool isImage, _) {
                      return ValueListenableBuilder(
                        valueListenable: _homeService.responseTextNotifier,
                        builder:
                            (BuildContext context, String responseText, _) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isImage)
                                ImageResponseWidget(
                                    imageUrl:
                                        _homeService.imageDataNotifier.value)
                              else
                                TypewriterText(
                                  text: responseText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              // bottom container
              Container(
                width: double.infinity,
                height: 253,
                decoration: BoxDecoration(
                  color: homeScreenFooter,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(80.0),
                    topRight: Radius.circular(80.0),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      height: 150,
                      width: double.infinity,
                      child: Center(
                        // input text display area
                        child: ValueListenableBuilder(
                            valueListenable:
                                _homeService.recognizedTextNotifier,
                            builder: (BuildContext context, String result, _) {
                              return Text(
                                result,
                                style: const TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.clip,
                                maxLines: 3,
                              );
                            }),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: size > 200 ? size - 200 : 0,
                          child: TextField(
                            controller: _inputController,
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _homeService.isTyping = false;
                              } else {
                                _homeService.isTyping = true;
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              hintText: 'Ask Luna',
                              hintStyle: const TextStyle(
                                color: textFieldHintColor,
                              ),
                            ),
                            style: const TextStyle(
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                        kWidth20,
                        // voice record button
                        _homeService.isTyping
                            ? SendButton(
                                onSend: () {
                                  _homeService.sendText(_inputController.text);
                                  _inputController.clear();
                                  _homeService.isTyping = false;
                                },
                              )
                            : VoiceRecordButton(
                                onStart: () async {
                                  await _homeService.startListening();
                                },
                                onStop: () async {
                                  await _homeService.stopListening();
                                },
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
