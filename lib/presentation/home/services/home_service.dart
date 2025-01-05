import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
  ValueNotifier<bool> isTextMessageNotifier = ValueNotifier<bool>(false);
  bool isListening = false;
  bool isTyping = false;
  String recognizedText = '';
  String imageUrl = '';
  bool isText = false;

  // For Setting Alarm
  Map<String, int> weekdayMap = {
    "monday": DateTime.monday,
    "tuesday": DateTime.tuesday,
    "wednesday": DateTime.wednesday,
    "thursday": DateTime.thursday,
    "friday": DateTime.friday,
    "saturday": DateTime.saturday,
    "sunday": DateTime.sunday,
  };

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

  // Setting Alarm For WeekDays
  Future<DateTime> getNextWeekDayDate(String weekday, int time) async {
    final now = DateTime.now();
    int targetWeekday = weekdayMap[weekday.toLowerCase()]!;
    int daysToAdd = (targetWeekday - now.weekday + 7) % 7;
    daysToAdd = daysToAdd == 0 ? 7 : daysToAdd; // Ensure date is in future

    final nextWeekday = now.add(Duration(days: daysToAdd));

    return DateTime(
        nextWeekday.year, nextWeekday.month, nextWeekday.day, time, 0);
  }

  // Say Greetings
  void sayGreetings() {
    // get a random greeting from the list
    index = Random().nextInt(greetings.length);
    final String greeting = greetings[index];
    _ttsService.speak(greeting);
  }

  // Process data based on intent
  Future<void> processData(String intent, String textData) async {
    final List<DataModel?> results = await _service.fetchData(textData);
    if (results.isEmpty) {
      // do nothing
    } else {
      for (var result in results) {
        dev.log("Entity : ${result!.entity} Word: ${result.word}");
      }
    }
    // Intents
    if (textData.contains("image") || textData.contains("generate")) {
      isImageNotifier.value = true;
      _ttsService.speak(
          "Sure! I'm working on creating your image now. This might take a moment—hang tight!");
      await generateImage(textData);
    }
    // Toggle On
    else if (intent == 'iot_wemo_on') {
      dev.log(results[0]!.word.toString());
      final String word = results[0]!.word!.toLowerCase();
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
      dev.log(results[0]!.word.toString());
      final String word = results[0]!.word!.toLowerCase();
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
    }
    // Audio Volume Down
    else if (intent == 'audio_volume_down') {
      _settingsController.toggleAudioDown();
      _ttsService.speak("volume reduced");
    }
    // Alarm Set
    else if (intent == "alarm_set") {
      DateTime now = DateTime.now();
      DateTime? alarmTime;
      String? time;
      int? hour;
      int? minute;
      String? date;
      String? period;

      for (int i = 0; i < results.length; i++) {
        final entity = results[i]?.entity; // Use safe access

        if (entity == "B-time") {
          time = (time ?? "") +
              (results[i]?.word?.trim() ?? ""); // Use safe access
        } else if (entity == "I-time") {
          period = (period ?? "") +
              (results[i]?.word?.trim().toLowerCase() ?? ""); // Safe access
        } else if (entity == "B-date") {
          date = (date ?? "") +
              (results[i]?.word?.trim().toLowerCase() ?? ""); // Safe access
        }
      }

      // Remove the starting character if date is not null
      if (date != null && date.isNotEmpty) {
        date = date.substring(1); // to remove the starting character _
      }
      if (period != null && period.isNotEmpty) {
        period = period.replaceAll(".", "");
        period = period.substring(1);
      }

      if (time != null) {
        // Remove leading character if necessary
        time = time.substring(1); // Ensure this is assigned back to time
        List<String> timeParts = time.split(':');

        if (timeParts.length == 2) {
          hour = int.tryParse(timeParts[0]);
          minute = int.tryParse(timeParts[1]);
          dev.log("hour : $hour minute: $minute");
        } else {
          dev.log("Invalid time format: $time");
        }

        if (period != null) {
          // Check if period is not null
          if (period.toLowerCase() == "pm" && hour != null && hour != 12) {
            hour = (hour + 12);
          } else if (period.toLowerCase() == "am" && hour == 12) {
            hour = 0;
          }
        }

        dev.log(
            "time : $time am/pm : $period date: $date hour: $hour minute: $minute");

        // If Only Time Is Given
        if (date == null || date.isEmpty) {
          alarmTime = DateTime(
              now.year, now.month, now.day, hour ?? now.hour, minute ?? 0);
          if (alarmTime.isBefore(now)) {
            alarmTime = alarmTime.add(const Duration(days: 1));
          }
        } else if (date == "tomorrow") {
          alarmTime = DateTime(
              now.year, now.month, now.day + 1, hour ?? now.hour, minute ?? 0);
        } else if (weekdayMap.containsKey(date.toLowerCase())) {
          alarmTime = await getNextWeekDayDate(date, hour!);
        }

        dev.log(alarmTime.toString());
        // Check if alarmTime is not null
        if (alarmTime != null) {
          _settingsController.toggleAlarm(alarmTime.year, alarmTime.month,
              alarmTime.day, alarmTime.hour, alarmTime.minute);
          _ttsService.speak("alarm set for $time $period $date");
        }
      } else {
        _ttsService
            .speak("Please provide information about when to set the alarm");
        responseTextNotifier.value =
            "Please provide information about when to set the alarm";
      }
    } else {
      responseTextNotifier.value = "please connect to the internet";
      responseTextNotifier.notifyListeners();
      _ttsService.speak("please connect to the internet");
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
}
