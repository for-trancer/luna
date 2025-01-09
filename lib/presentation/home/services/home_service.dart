import 'dart:developer' as dev;
import 'dart:math';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:luna/application/models/data/data_model.dart';
import 'package:luna/application/models/image/image_model.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/services/main_service.dart';
import 'package:luna/presentation/home/services/Tts_Service.dart';
import 'package:luna/services/settings_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Package Names
  Map<String, String> appNameToPackageName = {
    'spotify': 'com.spotify.music',
    'youtube': 'com.google.android.youtube',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'twitter': 'com.twitter.android',
    'whatsapp': 'com.whatsapp',
    'telegram': 'org.telegram.messenger',
    'snapchat': 'com.snapchat.android',
    'netflix': 'com.netflix.mediaclient',
    'amazon': 'com.amazon.mShop.android.shopping',
    'google maps': 'com.google.android.apps.maps',
    'google drive': 'com.google.android.apps.docs',
    'gmail': 'com.google.android.gm',
    'linkedin': 'com.linkedin.android',
    'pinterest': 'com.pinterest',
    'reddit': 'com.reddit.frontpage',
    'tiktok': 'com.zhiliaoapp.musically',
    'discord': 'com.discord',
    'slack': 'com.Slack',
    'zoom': 'us.zoom.videomeetings',
    'microsoft teams': 'com.microsoft.teams',
    'viber': 'com.viber.voip',
    'skype': 'com.skype.raider',
    'uber': 'com.ubercab',
    'lyft': 'me.lyft.android',
    'ebay': 'com.ebay.mobile',
    'yelp': 'com.yelp.android',
    'spotify lite': 'com.spotify.lite',
    'google photos': 'com.google.android.apps.photos',
    'acrobat': 'com.adobe.reader',
    'microsoft word': 'com.microsoft.office.word',
    'microsoft excel': 'com.microsoft.office.excel',
    'microsoft powerpoint': 'com.microsoft.office.powerpoint',
    // System Apps
    'camera': 'com.android.camera', // Default camera app
    'settings': 'com.android.settings', // Settings app
    'contacts': 'com.android.contacts', // Contacts app
    'phone': 'com.android.dialer', // Phone app
    'messages': 'com.android.mms', // Messaging app
    'gallery': 'com.android.gallery3d', // Default gallery app
    'clock': 'com.android.deskclock', // Clock app
    'maps': 'com.google.android.apps.maps', // Google Maps
    'play store': 'com.android.vending', // Google Play Store
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

  Future<List<Contact>> fetchContacts() async {
    return await FlutterContacts.getContacts(withProperties: true);
  }

  // Generate image based on prompt
  Future<void> generateImage(String prompt) async {
    try {
      ImageModel result = await _service.fetchImage(prompt);
      isImageNotifier.value = true;
      isImageNotifier.notifyListeners();
      imageDataNotifier.value = result.image ?? '';
      imageDataNotifier.notifyListeners();
      _ttsService.speak(
          "Your image is ready! Here it is. Let me know if you'd like to create another one");
      dev.log('Generated image Data: ${result.image}');
    } catch (e) {
      isImageNotifier.value = false;
      _ttsService.speak(
          "Failed to generate the image. Please try again later or check your network connection.");
      dev.log(e.toString());
    }
  }

  Future<void> getContactDetails(String contactName) async {
    List<Contact> contacts = await fetchContacts();
    List<String> matchingNames = [];
    List<Phone> phoneNumbers = [];
    int matchCount = 0;

    for (var contact in contacts) {
      // Check for partial match
      if (contact.displayName
          .toLowerCase()
          .contains(contactName.toLowerCase())) {
        matchingNames.add(contact.displayName);
        phoneNumbers.add(contact.phones.first);
        matchCount++;
      }
    }

    if (matchCount > 1) {
      String errorText =
          "There are multiple contacts saved under that name. Please specify which one to call";
      await _ttsService.flutterTts.speak(errorText);
      responseTextNotifier.value = errorText;
      await Future.delayed(const Duration(seconds: 5));

      for (var name in matchingNames) {
        await _ttsService.flutterTts.speak(name);
        await Future.delayed(const Duration(seconds: 2));
      }
    } else if (matchCount == 0) {
      String errorText = "No contact named $contactName found!";
      await _ttsService.flutterTts.speak(errorText);
      responseTextNotifier.value = errorText;
    } else if (matchCount == 1) {
      // If exactly one contact is found, handle the call
      String successText = "Calling ${matchingNames[0]}.";
      await _ttsService.flutterTts.speak(successText);
      responseTextNotifier.value = successText;
      makeCall(phoneNumbers[0].number);
      // Logic to initiate the call can be added here
    }
  }

  Future<void> makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    requestSmsPermission();
    if (await canLaunch(smsUri.toString())) {
      await launch(smsUri.toString());
    } else {
      throw 'Could not launch $smsUri';
    }
  }

  Future<void> requestCallPermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }
  }

  Future<void> requestSmsPermission() async {
    // Check the current status of SMS permission
    var status = await Permission.sms.status;

    // If the permission is denied, request it
    if (status.isDenied) {
      await Permission.sms.request();
    }

    // Check the permission status again after requesting
    if (await Permission.sms.isGranted) {
      print("SMS permission granted.");
      // Proceed with SMS functionality
    } else {
      print("SMS permission denied.");
      // Handle the case when permission is denied
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

  // Fetch Package Name Of An App
  String getPackageName(String appName) {
    return appNameToPackageName[appName] ?? "";
  }

  // Send Message
  Future<void> sendTextMessage(String contactName, String textData) async {
    List<Contact> contacts = await fetchContacts();
    List<String> matchingNames = [];
    List<Phone> phoneNumbers = [];
    int matchCount = 0;

    for (var contact in contacts) {
      // Check for partial match
      if (contact.displayName
          .toLowerCase()
          .contains(contactName.toLowerCase())) {
        matchingNames.add(contact.displayName);
        phoneNumbers.add(contact.phones.first);
        matchCount++;
      }
    }

    if (matchCount > 1) {
      String errorText =
          "There are multiple contacts saved under that name. Please specify which one to text";
      await _ttsService.flutterTts.speak(errorText);
      responseTextNotifier.value = errorText;
      await Future.delayed(const Duration(seconds: 6));

      for (var name in matchingNames) {
        await _ttsService.flutterTts.speak(name);
        await Future.delayed(const Duration(seconds: 2));
      }
    } else if (matchCount == 0) {
      String errorText = "No contact named $contactName found!";
      await _ttsService.flutterTts.speak(errorText);
      responseTextNotifier.value = errorText;
    } else if (matchCount == 1) {
      Future<String?> sendMsg;
      // If exactly one contact is found, handle the text
      String successText = "sending text to ${matchingNames[0]}.";
      await _ttsService.flutterTts.speak(successText);
      responseTextNotifier.value = successText;

      String result;

      sendMsg = _service.fetchInformation(
          "Extract only the message content from the following instruction dont say any other things:" +
              textData);
      sendMsg.then((value) {
        result = value ?? '';
        dev.log(result);
        sendSMS(phoneNumbers[0].number, result);
      });
    }
  }

  // Send Email
  Future<void> sendEmail(String email, String subject, String msg) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters({
        'subject': subject,
        'body': msg,
      }),
    );

    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  // Helper function to encode query parameters
  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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
    isImageNotifier.value = false;
    imageDataNotifier.value = "";
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
          String alarmText;
          if (date != null && period != null) {
            alarmText = "alarm set for $time $period $date";
            _ttsService.speak(alarmText);
          } else if (date != null) {
            alarmText = "alarm set for $time $date";
            _ttsService.speak(alarmText);
          } else {
            alarmText = "alarm set for $time $period";
            _ttsService.speak(alarmText);
          }
          responseTextNotifier.value = alarmText;
        }
      } else {
        _ttsService
            .speak("Please provide information about when to set the alarm");
        responseTextNotifier.value =
            "Please provide information about when to set the alarm";
      }
    }
    // Open App
    else if (textData.contains("open")) {
      textData = textData.toLowerCase();
      String? appName;
      String? packageName;
      if (results.isNotEmpty) {
        for (var model in results) {
          appName = (appName ?? '') + (model!.word!.trim().toLowerCase());
        }
        appName = appName!.substring(1);
        dev.log(appName);
        packageName = getPackageName(appName);
        if (packageName.isNotEmpty) {
          _ttsService.speak("opening $appName");
          _settingsController.openApp(packageName);
        } else {
          _ttsService.speak("App not found");
        }
      } else {
        if (textData.contains("settings") || textData.contains("setting")) {
          packageName = getPackageName("settings");
          _ttsService.speak("opening settings");
          _settingsController.openApp(packageName);
        } else if (textData.contains("email") || textData.contains("gmail")) {
          packageName = getPackageName("gmail");
          _ttsService.speak("opening gmail");
          _settingsController.openApp(packageName);
        } else if (textData.contains("message") ||
            textData.contains("messages")) {
          packageName = getPackageName("messsages");
          _ttsService.speak("opening messages");
          _settingsController.openApp(packageName);
        } else if (textData.contains("contact") ||
            textData.contains("contacts")) {
          packageName = getPackageName("contacts");
          _ttsService.speak("opening contacts");
          _settingsController.openApp(packageName);
        } else if (textData.contains("whatsapp")) {
          packageName = getPackageName("whatsapp");
          _ttsService.speak("opening whatsapp");
          _settingsController.openApp(packageName);
        } else if (textData.contains("discord")) {
          packageName = getPackageName("discord");
          _ttsService.speak("opening discord");
          _settingsController.openApp(packageName);
        } else if (textData.contains("google photos") ||
            textData.contains("photos")) {
          packageName = getPackageName("google photos");
          _ttsService.speak("opening google photos");
          _settingsController.openApp(packageName);
        } else if (textData.contains("google map") ||
            textData.contains("map")) {
          packageName = getPackageName("maps");
          _ttsService.speak("opening google maps");
          _settingsController.openApp(packageName);
        } else {
          _ttsService.speak("please specify the app name");
        }
      }
    }
    // Play music
    else if (intent == "play_music") {
      String? artistName;
      String? songName;
      String? searchText;
      if (results.isNotEmpty) {
        for (var model in results) {
          if (model!.entity == "B-song_name") {
            songName = (songName ?? '') + (model.word!.trim());
          } else if (model.entity == "B-artist_name" ||
              model.entity == "I-artist_name") {
            artistName = (artistName ?? '') + (model.word!.trim());
          }
        }
        if (songName != null || artistName != null) {
          if (songName != null) {
            songName = songName.substring(1).replaceAll("▁", " ");
          }
          if (artistName != null) {
            artistName = artistName.substring(1).replaceAll("▁", " ");
          }
          searchText = "$songName $artistName";
          String songText;
          if (songName != null && artistName != null) {
            songText = "playing $songName by $artistName";
            _ttsService.speak(songText);
            responseTextNotifier.value = songText;
          } else if (songName != null) {
            songText = "playing $songName";
            _ttsService.speak(songText);
            responseTextNotifier.value = songText;
          } else {
            songText = "playing an song sung by $artistName";
            _ttsService.speak(songText);
            responseTextNotifier.value = songText;
          }
          _settingsController.playYoutube(searchText);
        } else {
          String songText =
              "Got it! Please tell me the name of the song or the artist you'd like to listen to.";
          _ttsService.speak(songText);
          responseTextNotifier.value = songText;
        }
      } else {
        String songText;
        songText =
            "Sure! Could you tell me the name of the song or artist you'd like me to play?";
        _ttsService.speak(songText);
        responseTextNotifier.value = songText;
      }
    }
    // Call
    else if (textData.contains("call")) {
      if (results.isNotEmpty) {
        String? contactName;
        for (var model in results) {
          if (model!.entity == "B-person" ||
              model.entity == "I-person" ||
              model.entity == "B-relation") {
            contactName = (contactName ?? '') + (model.word!.trim());
          }
        }
        contactName = contactName!.substring(1).replaceAll("▁", " ");
        getContactDetails(contactName);
      } else {
        String errorText = "please tell me who to call?";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
      }
    }
    // Text Message
    else if (textData.contains("text") ||
        textData.contains("text message") ||
        textData.contains("message")) {
      String errorText;
      if (results.isNotEmpty) {
        String? contactName;
        for (var model in results) {
          if (model!.entity == "B-person" ||
              model.entity == "I-person" ||
              model.entity == "B-relation") {
            contactName = (contactName ?? "") + model.word!.trim();
          }
        }

        contactName = contactName!.substring(1).replaceAll("▁", " ");

        sendTextMessage(contactName, textData);
      } else {
        errorText = "please tell me who to text?";
      }
    }
    // Remove Alarm
    else if (intent == "alarm_remove") {
      _ttsService.speak("alarm is turned off");
      dev.log("alarm is turned off");
      _settingsController.toggleAlarmOff();
    }
    // Send Mail
    else if (intent == 'email_sendemail') {
      String? email;
      String? subject;
      String? msg;

      if (results.isNotEmpty) {
        for (var model in results) {
          if (model!.entity == "B-person" || model.entity == "I-person") {
            email = (email ?? "") + model.word!.trim().toString();
          }
        }

        email = email!.substring(1).replaceAll("▁", "") + "@gmail.com";
        email = email.toLowerCase();

        String? dataSubject = "Quick Remainder";
        String? dataMsg = await _service.fetchInformation(
            "Extract only the message body content from the following instruction. Don't say anything else, only the body content: " +
                textData);
        subject = dataSubject;
        msg = dataMsg;
        dev.log("Fetched subject: $subject");
        dev.log("Fetched message: $msg");

        _ttsService.speak("Sending mail to $email");
        responseTextNotifier.value = "Sending mail to $email";
        sendEmail(email, subject, msg!);
      } else {
        String errorText = "Please specify who to send the email to.";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
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
