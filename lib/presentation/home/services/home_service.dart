// ignore_for_file: prefer_interpolation_to_compose_strings, deprecated_member_use, invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:luna/application/models/data/data_model.dart';
import 'package:luna/application/models/image/image_model.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/infrastructure/api_keys.dart';
import 'package:luna/services/main_service.dart';
import 'package:luna/presentation/home/services/Tts_Service.dart';
import 'package:luna/services/offline_service.dart';
import 'package:luna/services/settings_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeService {
  final MainService _service = MainService();
  final NERService _nerService = NERService();
  final TtsService _ttsService = TtsService();
  final SettingsController _settingsController = SettingsController();
  final SmsQuery query = SmsQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

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

  String outputText = "";

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

  // For Reminder
  Map<String, int> monthMap = {
    "january": DateTime.january,
    "february": DateTime.february,
    "march": DateTime.march,
    "april": DateTime.april,
    "may": DateTime.may,
    "june": DateTime.june,
    "july": DateTime.july,
    "august": DateTime.august,
    "september": DateTime.september,
    "october": DateTime.october,
    "november": DateTime.november,
    "december": DateTime.december,
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

  // Nearby
  // category_mapping.dart

  Map<String, String> categoryMapping = {
    "hotel": "accommodation.hotel",
    "hut": "accommodation.hut",
    "apartment": "accommodation.apartment",
    "chalet": "accommodation.chalet",
    "guest house": "accommodation.guest_house",
    "hostel": "accommodation.hostel",
    "motel": "accommodation.motel",
    "restaurant": "catering.restaurant",
    "cafe": "catering.cafe",
    "bar": "catering.bar",
    "supermarket": "commercial.supermarket",
    "market": "commercial.marketplace",
    "shopping mall": "commercial.shopping_mall",
    "department store": "commercial.department_store",
    "gym": "sport.fitness.fitness_centre",
    "park": "leisure.park",
    "school": "education.school",
    "university": "education.university",
    "clinic": "healthcare.clinic_or_praxis",
    "hospital": "healthcare.hospital",
    "airport": "airport",
    "train station": "public_transport.train",
    "bus station": "public_transport.bus",
    "pet shop": "pet.shop",
    "veterinary": "pet.veterinary",
    "theatre": "entertainment.culture.theatre",
    "museum": "entertainment.museum",
    "zoo": "entertainment.zoo",
    "beach": "beach",
    "camping": "camping.camp_site",
    "car rental": "rental.car",
    "bicycle rental": "rental.bicycle",
    "gas station": "commercial.gas",
    "pharmacy": "commercial.health_and_beauty.pharmacy",
    "bank": "service.financial.bank",
    "atm": "service.financial.atm",
    "police station": "service.police",
    "fire station": "service.fire",
    "community center": "activity.community_center",
    "sport club": "activity.sport_club",
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
      OfflineService offlineService =
          OfflineService(responseTextNotifier: responseTextNotifier);
      bool isOffline = true;
      if (isOffline) {
        String intent =
            await offlineService.fetchIntent(recognizedTextNotifier.value);
        dev.log(intent);
        List<Map<String, dynamic>> entities =
            await _nerService.fetchEntities(userInput);
        dev.log(entities.toString());

        offlineService.processIntent(intent, entities, userInput);
      }
      //  else {
      //   final prediction = await _service.fetchIntentPrediction(userInput);
      //   dev.log(prediction.label.toString());
      //   await processData(prediction.label!, userInput);
      // }
    } catch (e) {
      // Handle error
      dev.log(e.toString());
    }
  }

  // Get Current Location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _ttsService.speak("Location services are disabled");
      return Future.error("Location servicse are disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _ttsService.speak("Location permissions are denied");
        return Future.error("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _ttsService.speak("location permissions are denied permanently");
      return Future.error("Location permissions are denied permanently");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  //Get Destination Location
  Future<List<Location>> getDestinationLocation(String address) async {
    List<Location> locations = await locationFromAddress(address);
    return locations;
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

  // Navigation
  void launchMaps(Position current, Location destination) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}');
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    requestSmsPermission();
    // ignore: deprecated_member_use
    if (await canLaunch(smsUri.toString())) {
      // ignore: deprecated_member_use
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
    var status = await Permission.sms.status;

    if (status.isDenied) {
      await Permission.sms.request();
    }

    if (await Permission.sms.isGranted) {
      print("SMS permission granted.");
    } else {
      print("SMS permission denied.");
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

  // Weather Info
  Future<Map<String, dynamic>> getCurrentWeather() async {
    Position location = await getCurrentLocation();
    final String url =
        'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=${location.latitude},${location.longitude}&aqi=no';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      dev.log(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('failed to load weather data');
    }
  }

  // Flashlight
  Future<void> toggleFlashLight(bool enable) async {
    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      final cameraController =
          CameraController(cameras.first, ResolutionPreset.high);
      await cameraController.initialize();

      if (enable) {
        _ttsService.speak("turning on flashlight");
        await cameraController.setFlashMode(FlashMode.torch);
      } else {
        _ttsService.speak("turning off flashlight");
        await cameraController.setFlashMode(FlashMode.off);
      }
    } else {
      _ttsService.speak("no flashlight is available for this device");
    }
  }

  // Stop Music
  Future<void> stopMusic() async {
    _ttsService.speak("stoping music");
    await _audioPlayer.stop();
  }

  // News Topic
  Future<Map<String, dynamic>> getTopicNews(String query) async {
    DateTime today = DateTime.now();
    DateTime dateMinus15Days = today.subtract(const Duration(days: 30));
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateMinus15Days);
    dev.log(formattedDate);
    String url =
        "https://newsapi.org/v2/everything?q=$query&from=$formattedDate&sortBy=popularity&apiKey=$newsApiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      dev.log(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('failed to get topic news');
    }
  }

  // News Local
  Future<Map<String, dynamic>> getLocalNews() async {
    const String url =
        "https://newsapi.org/v2/top-headlines?country=us&apiKey=$newsApiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      dev.log(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('failed to get local news');
    }
  }

  Future<Map<String, dynamic>> getDestinationWeather(String destination) async {
    List<Location> locations = await getDestinationLocation(destination);
    Location location = locations.first;
    final String url =
        'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=${location.latitude},${location.longitude}&aqi=no';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      dev.log(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('failed to load weather data');
    }
  }

  // Nearby
  Future<Map<String, dynamic>> getNearbyDetails(String category) async {
    Position location = await getCurrentLocation();

    final String url =
        'https://api.geoapify.com/v2/places?categories=$category&filter=circle:${location.longitude},${location.latitude},5000&bias=proximity:${location.longitude},${location.latitude}&limit=5&apiKey=$geopifyApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      dev.log(response.body);
      return json.decode(response.body);
    } else {
      _ttsService.speak("unable to fetch the details");
      throw Exception('failed to get the data from geopify server3');
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
      outputText =
          "Sure! I'm working on creating your image now. This might take a moment—hang tight!";
      _ttsService.speak(outputText);
      await generateImage(textData);
    }
    // Toggle On
    else if (intent == 'iot_wemo_on') {
      if (results.isNotEmpty) {
        dev.log(results[0]!.word.toString());
        final String word = results[0]!.word!.toLowerCase();
        // Hotpot On
        if (textData.contains("hotspot")) {
          outputText = "Opening Hotspot Settings";
          hotspotSettings(outputText);
        }
        // Wifi On
        else if (word == '▁wifi' || textData.contains("Wi-Fi")) {
          outputText = "Please Turn On Wifi";
          wifiSettings(outputText);
        }
        // BlueTooth On
        else if (word == '▁bluetooth') {
          outputText = "Turning on Bluetooth";
          bool result = true;
          bluetoothSettings(outputText, result);
        }
      } else if (textData.contains("mobile data")) {
        outputText = "Opening mobile data settings";
        mobileDataSettings(outputText);
      } else {
        unclearInstruction();
      }
    }
    // Toggle Off
    else if (intent == 'iot_wemo_off') {
      if (results.isNotEmpty) {
        dev.log(results[0]!.word.toString());
        final String word = results[0]!.word!.toLowerCase();
        // Hotspot Off
        if (textData.contains("hotspot")) {
          outputText = "opening hotspot settings";
          hotspotSettings(outputText);
        }
        // BlueTooth Off
        else if (word == '▁bluetooth') {
          outputText = "Turning off Bluetooth";
          bool result = false;
          bluetoothSettings(outputText, result);
        }
        // Wifi Off
        else if (word == '▁wifi' || textData.contains("Wi-Fi")) {
          outputText = "Please turn off wifi";
          wifiSettings(outputText);
        } else if (textData.contains("mobile data")) {
          outputText = "Opening mobile data settings";
          mobileDataSettings(outputText);
        } else {
          unclearInstruction();
        }
      } else {
        unclearInstruction();
      }
    }
    // Audio Mute
    else if (intent == 'audio_volume_mute') {
      audioVolumeMute();
    }
    // Audio Full
    else if (intent == 'audio_volume_up') {
      audioVolumeMax();
    }
    // Audio Volume Down
    else if (intent == 'audio_volume_down') {
      audioVolumeReduce();
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
        final entity = results[i]?.entity;

        if (entity == "B-time") {
          time = (time ?? "") + (results[i]?.word?.trim() ?? "");
        } else if (entity == "I-time") {
          period =
              (period ?? "") + (results[i]?.word?.trim().toLowerCase() ?? "");
        } else if (entity == "B-date") {
          date = (date ?? "") + (results[i]?.word?.trim().toLowerCase() ?? "");
        }
      }

      if (date != null && date.isNotEmpty) {
        date = date.substring(1);
      }
      if (period != null && period.isNotEmpty) {
        period = period.substring(1).replaceAll(".", "");
      }

      if (time != null) {
        time = time.substring(1);
        List<String> timeParts = time.split(':');

        if (timeParts.length == 2) {
          hour = int.tryParse(timeParts[0]);
          minute = int.tryParse(timeParts[1]);
          dev.log("hour : $hour minute: $minute");
        } else {
          dev.log("Invalid time format: $time");
        }

        if (period != null) {
          if (period.toLowerCase() == "pm" && hour != null && hour != 12) {
            hour = (hour + 12);
          } else if (period.toLowerCase() == "am" && hour == 12) {
            hour = 0;
          }
        }

        dev.log(
            "time : $time am/pm : $period date: $date hour: $hour minute: $minute");

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

        if (alarmTime != null) {
          _settingsController.toggleAlarm(alarmTime.year, alarmTime.month,
              alarmTime.day, alarmTime.hour, alarmTime.minute);
          if (date != null && period != null) {
            outputText = "Alarm set for $time $period $date";
          } else if (date != null) {
            outputText = "Alarm set for $time $date";
          } else {
            outputText = "Alarm set for $time";
          }
          _ttsService.speak(outputText);
          responseTextNotifier.value = outputText;
        }
      } else {
        unclearInstruction();
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
          outputText = "Opening $appName";
          _ttsService.speak(outputText);
          responseTextNotifier.value = outputText;
          _settingsController.openApp(packageName);
        } else {
          outputText = "App not found";
          _ttsService.speak(outputText);
          responseTextNotifier.value = outputText;
        }
      } else {
        if (textData.contains("settings") || textData.contains("setting")) {
          packageName = getPackageName("settings");
          outputText = "Opening Settings";

          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("email") || textData.contains("gmail")) {
          packageName = getPackageName("gmail");

          outputText = "Opening Gmail";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("message") ||
            textData.contains("messages")) {
          packageName = getPackageName("messsages");

          outputText = "Opening Messages";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("contact") ||
            textData.contains("contacts")) {
          packageName = getPackageName("contacts");
          outputText = "Opening Contacts";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("whatsapp")) {
          packageName = getPackageName("whatsapp");

          outputText = "Opening Whatsapp";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("discord")) {
          packageName = getPackageName("discord");

          outputText = "Opening Discord";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("google photos") ||
            textData.contains("photos")) {
          packageName = getPackageName("google photos");
          outputText = "opening google photos";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else if (textData.contains("google map") ||
            textData.contains("map")) {
          packageName = getPackageName("maps");
          outputText = "Opening Google Maps";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
          _settingsController.openApp(packageName);
        } else {
          outputText = "Please Specify The App Name";
          responseTextNotifier.value = outputText;
          _ttsService.speak(outputText);
        }
      }
    }
    // Call
    else if (textData.contains("call")) {
      if (results.isNotEmpty) {
        String? contactName;
        for (var model in results) {
          if (model!.entity == "B-person" ||
              model.entity == "I-person" ||
              model.entity == "B-relation" ||
              model.entity == "B-business_name") {
            contactName = (contactName ?? '') + (model.word!.trim());
          }
        }
        contactName = contactName!.substring(1).replaceAll("▁", " ");
        getContactDetails(contactName);
      } else {
        String errorText = "Please tell me who to call?";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
      }
    }
    // Text Message
    else if (textData.contains("text") || textData.contains("text message")) {
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

        String? message = await _service.fetchInformation(
            "Extract only the message content from the following instruction from input prompt. Don't say anything else, only the message content: $textData");
        sendTextMessage(contactName, message!);
      } else {
        errorText = "Please tell me who to text?";
        responseTextNotifier.value = errorText;
      }
    }
    // Remove Alarm
    else if (intent == "alarm_remove") {
      outputText = "Alarm is turned off";
      _ttsService.speak(outputText);
      responseTextNotifier.value = outputText;
      _settingsController.toggleAlarmOff();
    }
    // Send Mail
    else if (intent == 'email_sendemail') {
      String? email;
      String? subject;
      String? msg;

      if (results.isNotEmpty) {
        for (var model in results) {
          if (model!.entity == "B-person" ||
              model.entity == "I-person" ||
              model.entity == "B-email_address" ||
              model.entity == "I-email_address") {
            email = (email ?? "") + model.word!.trim().toString();
          }
        }

        email = email!.substring(1).replaceAll("▁", "");
        email = email.toLowerCase();
        dev.log("email : $email");

        String? dataSubject = await _service.fetchInformation(
            "Extract an title for an gmail from this dont say any other things $textData");
        Future.delayed(const Duration(seconds: 4));
        String? dataMsg = await _service.fetchInformation(
            "Extract only the message body content from the following instruction. Don't say anything else, only the message body content: $textData");
        subject = dataSubject;
        msg = dataMsg;
        dev.log("Fetched subject: $subject");
        dev.log("Fetched message: $msg");

        outputText = "Sending mail to $email";
        _ttsService.speak(outputText);
        responseTextNotifier.value = outputText;
        sendEmail(email, subject!, msg!);
      } else {
        String errorText = "Please specify who to send the email to.";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
      }
    }
    // Read Message
    else if (intent == "email_query" && textData.contains("read")) {
      outputText = "Loading messages hang-tight!";
      _ttsService.speak(outputText);
      List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      );

      messages.sort((a, b) => b.date!.compareTo(a.date!));

      outputText = "";
      responseTextNotifier.value = outputText;

      for (int i = 0; i < 3; i++) {
        String? content = await _service.fetchInformation(
            "Extract the idea or key message from the following SMS text start uniquely and role play as voice assistant remove any mentioning of phonenumbers and ac numbers:" +
                messages[i].body!);
        outputText =
            "\n" + messages[i].address! + " : \n\n${messages[i].body}\n";
        responseTextNotifier.value = outputText;
        responseTextNotifier.notifyListeners();
        _ttsService.speak(
            "message from ${messages[i].address!} saying that" + content!);
        dev.log("${messages[i].address} ${messages[i].body} $content");
        await Future.delayed(Duration(seconds: content.length ~/ 8));
      }
    }
    // Reminder
    else if (intent == "calendar_set") {
      DateTime now = DateTime.now();
      DateTime? reminderTime;
      String? time;
      int? minute;
      int? hour;
      int? day;
      String? tempDay;
      String? month;
      String? period;
      String? title;

      if (results.isNotEmpty) {
        for (var model in results) {
          if (model!.entity == "B-date") {
            month = (month ?? '') + model.word!.trim().toLowerCase();
          } else if (model.entity == "I-date") {
            tempDay = (tempDay ?? '') + model.word!.trim().toLowerCase();
          } else if (model.entity == "B-time") {
            time = (time ?? '') + model.word!.trim();
          } else if (model.entity == "I-time") {
            period = (period ?? '') + model.word!.trim().toLowerCase();
          }
        }

        if (tempDay != null) {
          tempDay = tempDay.substring(1).replaceAll("▁", "");
          day = int.tryParse(tempDay);
        }

        if (month != null) {
          month = month.substring(1).replaceAll("▁", "");
        }

        if (period != null) {
          period = period.substring(1).replaceAll("▁", "");
          period = period.replaceAll(".", "");
        }

        if (time != null) {
          time = time.substring(1).replaceAll("▁", "");
          List<String> timeParts = time.split(":");

          if (timeParts.length == 2) {
            hour = int.tryParse(timeParts[0]);
            minute = int.tryParse(timeParts[1]);
          } else {
            dev.log("invalid time format: $time");
          }

          if (period != null) {
            if (period == "pm" && hour != null && hour != 12) {
              hour = (hour + 12);
            } else if (period == "am" && hour == 12) {
              hour = 0;
            }
          }

          dev.log(
              "time : $time am/pm : $period month: $month day:$day hour: $hour minute: $minute");

          if (month == null && tempDay == null) {
            dev.log("month tempday null");
            reminderTime = DateTime(
                now.year, now.month, now.day, hour ?? now.hour, minute ?? 0);
            if (reminderTime.isBefore(now)) {
              reminderTime = reminderTime.add(const Duration(days: 1));
            }
          } else if (month == "tomorrow") {
            dev.log("tommorow");
            reminderTime = DateTime(now.year, now.month, now.day + 1,
                hour ?? now.hour, minute ?? 0);
          } else if (weekdayMap.containsKey(month!.toLowerCase())) {
            dev.log("weekday map");
            reminderTime = await getNextWeekDayDate(month, hour!);
          } else if (monthMap.containsKey(month)) {
            dev.log("month map");
            int data = monthMap[month] ?? now.month;
            reminderTime = DateTime(now.year, data, day!, hour!, minute!);
          }

          try {
            String prompt =
                "Extract the reminder title from the following input. The reminder title is the phrase describing what the reminder is about, excluding any dates, times, or additional commands. Do not include any extra words, symbols, or formatting. Input: $textData";
            title = await _service.fetchInformation(prompt);
            dev.log("Extracted Title: $title");
          } catch (e) {
            dev.log("Error extracting title: $e");
          }

          if (reminderTime != null) {
            _settingsController.setReminder(
                reminderTime.year,
                reminderTime.month,
                reminderTime.day,
                reminderTime.hour,
                reminderTime.day,
                title!);
            dev.log(reminderTime.toString());
            _ttsService.speak("reminder set for $title");
          }
        }
      } else {
        _ttsService.speak("please specify when to set the remainder!");
      }
    }
    // Navigation
    else if (intent == "transport_query") {
      if (results.isNotEmpty) {
        String? destination;
        Position currentLocation;
        List<Location> destinations;
        Location location;
        for (var model in results) {
          if (model!.entity == "B-place_name" ||
              model.entity == "I-place_name") {
            destination = (destination ?? "") + (model.word!.trim());
          }
        }
        if (destination != null) {
          destination = destination.substring(1).replaceAll("▁", " ");
        }

        currentLocation = await getCurrentLocation();
        dev.log(
            "latitude: ${currentLocation.latitude} longitude: ${currentLocation.longitude}");
        destinations = await getDestinationLocation(destination!);
        location = destinations.first;
        dev.log(
            "latitude: ${location.latitude} longitude: ${location.longitude}");
        launchMaps(currentLocation, location);
        _ttsService.speak("starting navigation to $destination");
      } else {
        _ttsService.speak("please specify the destination");
      }
    }
    // Weather Query
    else if (intent == "weather_query") {
      Map<String, dynamic> weatherData;
      String location;
      String region;
      String condition;
      double tempC;
      double windMph;
      int humidity;
      double heatIndexC;
      if (results.isNotEmpty) {
        String? destination;
        for (var model in results) {
          if (model!.entity == "B-place_name" ||
              model.entity == "I-place_name") {
            destination = (destination ?? "") + (model.word!.trim());
          }
        }

        if (destination != null) {
          destination = destination.substring(1).replaceAll("▁", " ");

          weatherData = await getDestinationWeather(destination);

          location = weatherData['location']['name'];
          region = weatherData['location']['region'];
          condition = weatherData['current']['condition']['text'];
          tempC = weatherData['current']['temp_c'];
          windMph = weatherData['current']['wind_mph'];
          humidity = weatherData['current']['humidity'];
          heatIndexC = weatherData['current']['heatindex_c'];

          String response =
              "The current weather in $location, $region, is $condition with a temperature of $tempC°C. "
              "The wind is blowing at $windMph mph, and the humidity level is at $humidity%. "
              "The heat index feels like $heatIndexC°C.";
          responseTextNotifier.value = response;
          _ttsService.speak(response);
        } else {
          weatherData = await getCurrentWeather();

          location = weatherData['location']['name'];
          region = weatherData['location']['region'];
          condition = weatherData['current']['condition']['text'];
          tempC = weatherData['current']['temp_c'];
          windMph = weatherData['current']['wind_mph'];
          humidity = weatherData['current']['humidity'];
          heatIndexC = weatherData['current']['heatindex_c'];

          String response =
              "The current weather in $location, $region, is $condition with a temperature of $tempC°C. "
              "The wind is blowing at $windMph mph, and the humidity level is at $humidity%. "
              "The heat index feels like $heatIndexC°C.";
          responseTextNotifier.value = response;
          _ttsService.speak(response);
        }
      }
    }
    // News Query
    else if (intent == "news_query") {
      String? topic;
      String? textData;
      Map<String, dynamic> response;

      if (results.isNotEmpty) {
        for (var model in results) {
          topic = (topic ?? "") + model!.word!.trim();
        }

        if (topic != null) {
          topic = topic.substring(1).replaceAll("▁", " ");
          response = await getTopicNews(topic);
          _ttsService.speak("Here are the latest news articles about $topic");
          final articles = response['articles'] as List;
          final article = articles[0];
          _ttsService.flutterTts.setSpeechRate(0.5);
          textData = "${article['title']} \n\n ${article['description']}";
          responseTextNotifier.value = textData;
          _ttsService.speak(textData);
        }
      } else {
        response = await getLocalNews();
        _ttsService.speak("Here are the latest news articles!");
        final articles = response['articles'] as List;

        final article = articles[Random().nextInt(response.length)];
        _ttsService.flutterTts.setSpeechRate(0.5);
        textData = "${article['title']} \n\n${article['description']}";
        responseTextNotifier.value = textData;
        _ttsService.speak(textData);
      }
    } // Stop Music
    else if (intent == "play_music" && textData.contains("stop")) {
      stopMusic();
    }
    // Play Local Music
    else if (intent == "play_music") {
      if (results.isEmpty) {
        await playLocalAudio();
      } else {
        // Play Youtube Music
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
            if (songName == null) {
              searchText = artistName;
            } else if (artistName == null) {
              searchText = songName;
            } else {
              searchText = "$songName $artistName";
            }
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
            _settingsController.playYoutube(searchText!);
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
    }
    // Flashlight
    else if (intent == "iot_hue_lighton") {
      _ttsService.speak("turning on flashlight");
      toggleFlashLight(true);
    } else if (intent == "iot_hue_lightoff") {
      _ttsService.speak("turning off flashlight");
      toggleFlashLight(false);
    }
    // Nearby
    else if (intent == "recommendation_locations" ||
        intent == "recommendation_events" ||
        intent == "takeaway_query") {
      String? data;
      String category;
      Map<String, dynamic> response;

      if (results.isNotEmpty) {
        for (var model in results) {
          if (model!.entity == "B-business_name" ||
              model.entity == "I-business_name" ||
              model.entity == "B-business_type" ||
              model.entity == "I-business_type") {
            data = (data ?? "") + model.word!.trim();
          }
        }

        if (data != null) {
          data = data.substring(1).replaceAll("▁", " ").toLowerCase();
        }
        dev.log(data!);

        category = categoryMapping[data] ?? "";
        response = await getNearbyDetails(category);
        String name;
        String street;
        String textData = "Here is the list of available $data:\n\n";
        _ttsService.speak(textData);

        for (var model in response['features']) {
          name = model['properties']['name'] ?? "Unknown Name";
          street = model['properties']['street'] ?? "Unknown Street";

          if (name != "Unknown Name") {
            textData += "$name at $street\n";
          }
        }
        if (textData.trim().isNotEmpty) {
          responseTextNotifier.value = textData;
          _ttsService.speak(textData);
        }
      } else {
        _ttsService.speak("please specify the location,place,or name!");
      }
    } else if (intent == "iot_hue_lightup" && textData.contains("maximum")) {
      String outputText = "Screen brightness set to maximum";
      _ttsService.speak(outputText);
      responseTextNotifier.value = outputText;
      _settingsController.setMaxBrightness();
    } else if (intent == "iot_hue_lightup") {
      String outputText = "Screen brightness increased";
      _ttsService.speak(outputText);
      responseTextNotifier.value = outputText;
      _settingsController.increaseBrightness();
    } else if (intent == "iot_hue_lightdim") {
      String outputText = "Screen brightness decreased";
      _ttsService.speak(outputText);
      responseTextNotifier.value = outputText;
      _settingsController.decreaseBrightness();
    } else {
      dev.log("chatgpt");
      String? fetchedResponse = await _service.fetchInformation(textData);

      if (fetchedResponse != null) {
        responseTextNotifier.value = fetchedResponse;
        responseTextNotifier.notifyListeners();
        _ttsService.speak(responseTextNotifier.value);
      } else {
        dev.log("Failed to fetch information.");
        responseTextNotifier.value = "Sorry, I couldn't fetch the information.";
        _ttsService.speak(responseTextNotifier.value);
      }
    }
  }

  Future<void> playLocalAudio() async {
    String? _filePath;
    await _ttsService.speak(
        "unable to pick audio automatically,please select the audio file to play");

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.isNotEmpty) {
      _filePath = result.files.first.path;
    } else {
      _ttsService.speak("File Not Found");
    }

    if (_filePath != null) {
      try {
        await _audioPlayer.setFilePath(_filePath);
        _audioPlayer.play();
      } catch (e) {
        _ttsService.speak("Error Playing Audio");
      }
    }
  }

  void audioVolumeReduce() {
    _settingsController.toggleAudioDown();
    _ttsService.speak("volume reduced");
  }

  void audioVolumeMax() {
    outputText = "Volume set to full";
    _settingsController.toggleAudioFull();
    _ttsService.speak(outputText);
  }

  void unclearInstruction() {
    outputText = "Sorry, I didn't quite catch that";
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
  }

  void audioVolumeMute() {
    outputText = "Muting audio";
    responseTextNotifier.value = outputText;
    _ttsService.speak(outputText);
    _settingsController.toggleAudioMute(true);
  }

  void mobileDataSettings(String outputText) {
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
    _settingsController.openMobileDataSettings();
  }

  void bluetoothSettings(String outputText, bool result) {
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
    _settingsController.toggleBluetooth(result);
  }

  void wifiSettings(String outputText) {
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
    _settingsController.toggleWifi();
  }

  void hotspotSettings(String outputText) {
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
    _settingsController.toggleHotspot();
  }
}
