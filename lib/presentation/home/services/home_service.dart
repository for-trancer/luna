import 'dart:developer' as dev;
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:luna/application/models/data/data_model.dart';
import 'package:luna/application/models/image/image_model.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/services/main_service.dart';
import 'package:luna/presentation/home/services/Tts_Service.dart';
import 'package:luna/services/settings_controller.dart';

class HomeService {
  final MainService _service = MainService();
  final TtsService _ttsService = TtsService();
  final SettingsController _settingsController = SettingsController();

  int index = 0;

  ValueNotifier<String> recognizedTextNotifier = ValueNotifier<String>('');
  ValueNotifier<String> responseTextNotifier = ValueNotifier("");
  ValueNotifier<String> imageDataNotifier = ValueNotifier<String>("");
  ValueNotifier<bool> isImageNotifier = ValueNotifier<bool>(false);
  bool isListening = false;
  bool isTyping = false;
  String recognizedText = '';
  String imageUrl = '';
  bool isText = false;

  // Initialise speech and tts
  Future<void> initSpeechTts() async {
    _ttsService.initSpeech();
    _ttsService.initializeTTS();
    sayGreetings();
    responseTextNotifier.value = greetings[index];
  }

  // Start listening for speech
  Future<void> startListening() async {
    recognizedTextNotifier.value = '';
    if (!isListening) {
      isListening = true;
      await _ttsService.speechToText.listen(onResult: (result) {
        dev.log('result : ${result.recognizedWords}');
        recognizedTextNotifier.value = result.recognizedWords;
      });
    }
  }

  // Stop listening for speech
  Future<void> stopListening() async {
    if (isListening) {
      await _ttsService.speechToText.stop();
      isListening = false;
    }
    await getPrediction();
  }

  // Send text to server
  Future<void> sendText(String inputText) async {
    recognizedTextNotifier.value = inputText;
    await getPrediction();
  }

  // Get intent prediction
  Future<void> getPrediction() async {
    isImageNotifier.value = false;
    final userInput = recognizedTextNotifier.value;
    await _ttsService.flutterTts.speak(userInput);
    dev.log(recognizedTextNotifier.value);
    if (userInput.isEmpty || userInput.trim().isEmpty) {
      return;
    }
    try {
      final prediction = await _service.fetchIntentPrediction(userInput);
      dev.log(prediction.label.toString());
      await processData(prediction.label!, userInput);
    } catch (e) {
      // Handle error
      dev.log(e.toString());
    }
  }

  // Process data based on intent
  Future<void> processData(String intent, String textData) async {
    final DataModel? result = await _service.fetchData(textData);
    dev.log(result.toString());

    // Intents
    if (intent == 'general_quirky' ||
        intent == 'qa_definition' ||
        textData.contains("image") ||
        textData.contains("generate")) {
      isImageNotifier.value = true;
      _ttsService.speak(
          "Sure! I'm working on creating your image now. This might take a moment—hang tight!");
      await generateImage(textData);
    }
    // Toggle On
    else if (intent == 'iot_wemo_on') {
      dev.log(result!.word.toString());
      final String word = result.word!.toLowerCase();
      // Wifi On
      if (textData.contains("hotspot")) {
        _ttsService.speak("opening hotspot settings");
        _settingsController.toggleHotspot();
      } else if (word == '▁wifi' || textData.contains("Wi-Fi")) {
        _ttsService.speak("Turning on Wifi");
        _settingsController.toggleWifi(true);
      }
      // BlueTooth On
      else if (word == '▁bluetooth') {
        _ttsService.speak("Turning on Bluetooth");
        _settingsController.toggleBluetooth(true);
      }
    }
    // Toggle Off
    else if (intent == 'iot_wemo_off') {
      dev.log(result!.word.toString());
      final String word = result.word!.toLowerCase();
      // BlueTooth Off
      if (word == '▁bluetooth') {
        _ttsService.speak("Turning off Bluetooth");
        _settingsController.toggleBluetooth(false);
      }
      // Wifi Off
      if (word == '▁wifi' || textData.contains("Wi-Fi")) {
        _ttsService.speak("Turning off wifi");
        _settingsController.toggleWifi(false);
      }
      // Airplane Off
      if (textData.contains("airplane")) {
        _ttsService.speak("Turning off airplane mode");
        _settingsController.toggleAirplaneMode(false);
      }
    }
    // Audio Mute
    else if (intent == 'audio_volume_mute') {
      responseTextNotifier.value = "Muting audio";
      _settingsController.toggleAudioMute(true);
    }
    // Audio Full
    else if (intent == 'audio_volume_up') {
      _settingsController.toggleAudioFull();
      _ttsService.speak("Volume set to full");
    } else if (intent == 'audio_volume_down') {
      _settingsController.toggleAudioDown();
      _ttsService.speak("volume reduced");
    }
    /*else {
      dev.log("chatgpt");
      String? fetchedResponse = await _service.fetchInformation(textData);

      if (fetchedResponse != null) {
        responseTextNotifier.value = fetchedResponse;
        responseTextNotifier.notifyListeners();
        _ttsService.speak(responseTextNotifier.value);
      } else {
        // Handle the case where the response is null
        dev.log("Failed to fetch information.");
        responseTextNotifier.value =
            "Sorry, I couldn't fetch the information."; // Default message
        _ttsService.speak(responseTextNotifier.value);
      }
    }*/
  }

  // Generate image based on prompt
  Future<void> generateImage(String prompt) async {
    try {
      ImageModel result = await _service.fetchImage(prompt);
      _ttsService.speak(
          "Your image is ready! Here it is. Let me know if you'd like to create another one");
      isImageNotifier.value = true;
      dev.log('Generated image Data: ${result.image}');
      imageDataNotifier.value = result.image ?? '';
    } catch (e) {
      isImageNotifier.value = false;
      _ttsService.speak(
          "Failed to generate the image. Please try again later or check your network connection.");
      dev.log(e.toString());
    }
  }

  // Say Greetings
  void sayGreetings() {
    // get a random greeting from the list
    index = Random().nextInt(greetings.length);
    final String greeting = greetings[index];
    _ttsService.speak(greeting);
  }
}
