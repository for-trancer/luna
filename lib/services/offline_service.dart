// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:luna/presentation/home/services/home_service.dart';
// import 'package:luna/presentation/home/services/tts_service.dart';
// import 'package:luna/services/settings_controller.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

// class MobileBertTokenizer {
//   final Map<String, int> vocab;
//   final String clsToken;
//   final String sepToken;
//   final String padToken;
//   final String unkToken;

//   MobileBertTokenizer({
//     required this.vocab,
//     required this.clsToken,
//     required this.sepToken,
//     required this.padToken,
//     required this.unkToken,
//   });

//   /// Tokenizes [text] by lowercasing and splitting on whitespace.
//   /// It looks up each token in the vocabulary. For simplicity, this example
//   /// does not implement full subword (WordPiece) tokenization.
//   /// It prepends the [CLS] token and appends the [SEP] token, and pads
//   /// the sequence to [maxLength].

//   List<int> tokenize(String text, {int maxLength = 128}) {
//     text = text.toLowerCase();
//     // Basic whitespace splitting
//     List<String> words = text.split(RegExp(r'\s+'));

//     List<int> tokenIds = [];
//     // Add the [CLS] token.
//     tokenIds.add(vocab[clsToken] ?? 101);
//     for (var word in words) {
//       // Check if the word exists in the vocabulary.
//       // For production, use a proper subword algorithm.
//       if (vocab.containsKey(word)) {
//         tokenIds.add(vocab[word]!);
//       } else {
//         tokenIds.add(vocab[unkToken] ?? 100);
//       }
//     }
//     // Add the [SEP] token.
//     tokenIds.add(vocab[sepToken] ?? 102);

//     // Pad the sequence up to maxLength
//     if (tokenIds.length < maxLength) {
//       tokenIds +=
//           List.filled(maxLength - tokenIds.length, vocab[padToken] ?? 0);
//     } else if (tokenIds.length > maxLength) {
//       // Truncate the sequence and ensure [SEP] is at the end.
//       tokenIds = tokenIds.sublist(0, maxLength);
//       tokenIds[maxLength - 1] = vocab[sepToken] ?? 102;
//     }
//     return tokenIds;
//   }
// }

// class OfflineService {
//   late Interpreter _interpreter;
//   late Map<int, String> intentMapping;
//   late MobileBertTokenizer tokenizer;

//   String outputText = "";

//   final SettingsController _settingsController = SettingsController();
//   final TtsService _ttsService = TtsService();

//   ValueNotifier<String> responseTextNotifier = ValueNotifier("");

//   OfflineService({
//     required this.responseTextNotifier,
//   });

//   bool _isModelLoaded = false; // Flag to track model loading

//   /// Loads the TFLite model, intent mapping, vocabulary, and tokenizer configuration.
//   Future<void> loadModel() async {
//     // Load the TFLite model.
//     _interpreter =
//         await Interpreter.fromAsset('assets/mobilebert-luna/model.tflite');

//     // Load intent mapping from JSON.
//     String intentJsonStr = await rootBundle
//         .loadString('assets/mobilebert-luna/intent_mapping.json');
//     Map<String, dynamic> intentJsonMap = json.decode(intentJsonStr);
//     intentMapping = intentJsonMap
//         .map((key, value) => MapEntry(int.parse(key), value as String));

//     // Load vocabulary from vocab.txt (one token per line).
//     String vocabStr =
//         await rootBundle.loadString('assets/mobilebert-luna/vocab.txt');
//     List<String> vocabLines = const LineSplitter().convert(vocabStr);
//     Map<String, int> vocab = {};
//     for (int i = 0; i < vocabLines.length; i++) {
//       vocab[vocabLines[i]] = i;
//     }

//     // Load tokenizer configuration.
//     String tokenizerConfigStr = await rootBundle
//         .loadString('assets/mobilebert-luna/tokenizer_config.json');
//     Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);

//     // Retrieve special tokens from the configuration.
//     String clsToken = tokenizerConfig['cls_token'] ?? "[CLS]";
//     String sepToken = tokenizerConfig['sep_token'] ?? "[SEP]";
//     String padToken = tokenizerConfig['pad_token'] ?? "[PAD]";
//     String unkToken = tokenizerConfig['unk_token'] ?? "[UNK]";

//     // Create an instance of MobileBertTokenizer.
//     tokenizer = MobileBertTokenizer(
//       vocab: vocab,
//       clsToken: clsToken,
//       sepToken: sepToken,
//       padToken: padToken,
//       unkToken: unkToken,
//     );

//     _isModelLoaded = true;
//     log("Model, intent mapping, and tokenizer loaded.");
//   }

//   /// Processes [inputText] by tokenizing it, running inference, and returning
//   /// the predicted intent.
//   Future<String> fetchIntent(String inputText) async {
//     // Ensure the model is loaded.
//     if (!_isModelLoaded) {
//       await loadModel();
//     }

//     // Tokenize the input text.
//     List<int> inputIds = tokenizer.tokenize(inputText, maxLength: 128);

//     // Create an attention mask: 1 for non-[PAD] tokens, 0 for padding tokens.
//     int padId = tokenizer.vocab[tokenizer.padToken] ?? 0;
//     List<int> attentionMask =
//         inputIds.map((id) => id == padId ? 0 : 1).toList();

//     // Convert the lists to Int32List, because the model expects int32.
//     Int32List inputIds32 = Int32List.fromList(inputIds);
//     Int32List mask32 = Int32List.fromList(attentionMask);

//     // Create input tensors with shape [1, 128].
//     var inputTensor = [inputIds32];
//     var maskTensor = [mask32];

//     // Prepare the output buffer with shape [1, numClasses].
//     int numClasses = intentMapping.length;
//     var outputTensor =
//         List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

//     // Run inference synchronously.
//     _interpreter
//         .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});

//     // Convert output tensor (logits) to a list of doubles.
//     List<double> logits = List<double>.from(outputTensor[0]);
//     List<double> probabilities = softmax(logits);

//     // Get the index with the highest probability.
//     int predictedIndex = argMax(probabilities);
//     String predictedIntent = intentMapping[predictedIndex] ?? "Unknown";
//     double confidence = probabilities[predictedIndex];
//     log("\nIntent: $predictedIntent (Confidence: ${(confidence * 100).toStringAsFixed(2)}%)");

//     return predictedIntent;
//   }

//   /// Computes softmax for the list of logits.
//   List<double> softmax(List<double> logits) {
//     double maxLogit = logits.reduce(math.max);
//     List<double> exps = logits.map((e) => math.exp(e - maxLogit)).toList();
//     double sumExps = exps.reduce((a, b) => a + b);
//     return exps.map((e) => e / sumExps).toList();
//   }

//   /// Returns the index of the maximum value in the list.
//   int argMax(List<double> list) {
//     double maxValue = list[0];
//     int maxIndex = 0;
//     for (int i = 1; i < list.length; i++) {
//       if (list[i] > maxValue) {
//         maxValue = list[i];
//         maxIndex = i;
//       }
//     }
//     log("\nMax value: $maxValue");
//     return maxIndex;
//   }

//   void processIntent(
//       String intent, List<Map<String, dynamic>> results, String textData) {
//     Map<String, dynamic> firstItem;
//     textData = textData.toLowerCase();
//     // Flashlight On
//     if (intent == "iot_hue_lightdim" || intent == "iot_hue_lighton") {
//       if (textData.contains("flashlight")) {
//         bool status = true;
//         toggleFlashLight(status);
//       } else if (textData.contains("brightness")) {
//         String outputText = "Screen brightness decreased";
//         _ttsService.speak(outputText);
//         responseTextNotifier.value = outputText;
//         _settingsController.decreaseBrightness();
//       }
//     } else if (intent == "iot_hue_lightup" && textData.contains("maximum")) {
//       String outputText = "Screen brightness set to maximum";
//       _ttsService.speak(outputText);
//       responseTextNotifier.value = outputText;
//       _settingsController.setMaxBrightness();
//     } else if (intent == "iot_hue_lightup") {
//       String outputText = "Screen brightness increased";
//       _ttsService.speak(outputText);
//       responseTextNotifier.value = outputText;
//       _settingsController.increaseBrightness();
//     }
//     // FlashLight Off
//     else if (intent == "iot_hue_lightoff") {
//       bool status = false;
//       toggleFlashLight(status);
//     }
//     // Toggle Switch On
//     else if (textData.contains("turn on") || textData.contains("enable")) {
//       log("turn on settings");
//       String word = "";

//       for (var data in results) {
//         word = word + (data['word'].trim().toLowerCase());
//       }
//       // Hotspot On
//       if (textData.contains("hotspot")) {
//         outputText = "Opening Hotspot Settings";
//         hotspotSettings(outputText);
//       }
//       // Wifi On
//       else if (word == 'wifi' || textData.contains("wi-fi")) {
//         outputText = "Please Turn On Wifi";
//         wifiSettings(outputText);
//       }
//       // BlueTooth On
//       else if (word == 'bluetooth') {
//         outputText = "Turning on Bluetooth";
//         bool result = true;
//         bluetoothSettings(outputText, result);
//       }
//       // MobileData On
//       else if (textData.contains("mobile data")) {
//         outputText = "Opening mobile data settings";
//         mobileDataSettings(outputText);
//       } else {
//         unclearInstruction();
//       }
//     }
//     // Toggle Off
//     else if (intent == "iot_wemo_off") {
//       String word = "";
//       if (results.isNotEmpty) {
//         for (var data in results) {
//           word = word + (data['word'].trim().toLowerCase());
//         }
//       }
//       // Due to Model Error
//       if (textData.contains("turn on") || textData.contains("enable")) {
//         // Hotspot On
//         if (textData.contains("hotspot")) {
//           outputText = "Opening Hotspot Settings";
//           hotspotSettings(outputText);
//         }
//         // Wifi On
//         else if (word == 'wifi' || textData.contains("wi-fi")) {
//           outputText = "Please Turn On Wifi";
//           wifiSettings(outputText);
//         }
//         // BlueTooth On
//         else if (word == 'bluetooth') {
//           outputText = "Turning on Bluetooth";
//           bool result = true;
//           bluetoothSettings(outputText, result);
//         }
//         // MobileData On
//         else if (textData.contains("mobile data")) {
//           outputText = "Opening mobile data settings";
//           mobileDataSettings(outputText);
//         } else {
//           unclearInstruction();
//         }
//       }
//       // Off
//       if (textData.contains("hotspot")) {
//         outputText = "opening hotspot settings";
//         hotspotSettings(outputText);
//       }
//       // BlueTooth Off
//       else if (word == 'bluetooth' || textData.contains("bluetooth")) {
//         outputText = "Turning off Bluetooth";
//         bool result = false;
//         bluetoothSettings(outputText, result);
//       }
//       // Wifi Off
//       else if (word == 'wifi' || textData.contains("wi-fi")) {
//         outputText = "Please turn off wifi";
//         wifiSettings(outputText);
//       } else if (textData.contains("mobile data")) {
//         outputText = "Opening mobile data settings";
//         mobileDataSettings(outputText);
//       } else {
//         unclearInstruction();
//       }
//     }
//     // Audio Mute
//     else if (intent == 'audio_volume_mute') {
//       audioVolumeMute();
//     }
//     // Audio Full
//     else if (intent == 'audio_volume_up') {
//       audioVolumeMax();
//     }
//     // Audio Volume Down
//     else if (intent == 'audio_volume_down') {
//       audioVolumeReduce();
//     }
//   }

//   // Flashlight
//   Future<void> toggleFlashLight(bool enable) async {
//     final cameras = await availableCameras();

//     if (cameras.isNotEmpty) {
//       final cameraController =
//           CameraController(cameras.first, ResolutionPreset.high);
//       await cameraController.initialize();

//       if (enable) {
//         _ttsService.speak("turning on flashlight");
//         await cameraController.setFlashMode(FlashMode.torch);
//       } else {
//         _ttsService.speak("turning off flashlight");
//         await cameraController.setFlashMode(FlashMode.off);
//       }
//     } else {
//       _ttsService.speak("no flashlight is available for this device");
//     }
//   }

//   void audioVolumeReduce() {
//     _settingsController.toggleAudioDown();
//     _ttsService.speak("volume reduced");
//   }

//   void audioVolumeMax() {
//     outputText = "Volume set to full";
//     _settingsController.toggleAudioFull();
//     _ttsService.speak(outputText);
//   }

//   void unclearInstruction() {
//     outputText = "Sorry, I didn't quite catch that";
//     _ttsService.speak(outputText);
//     responseTextNotifier.value = outputText;
//   }

//   void audioVolumeMute() {
//     outputText = "Muting audio";
//     responseTextNotifier.value = outputText;
//     _ttsService.speak(outputText);
//     _settingsController.toggleAudioMute(true);
//   }

//   void mobileDataSettings(String outputText) {
//     _ttsService.speak(outputText);
//     responseTextNotifier.value = outputText;
//     _settingsController.openMobileDataSettings();
//   }

//   void bluetoothSettings(String outputText, bool result) {
//     _ttsService.speak(outputText);
//     responseTextNotifier.value = outputText;
//     _settingsController.toggleBluetooth(result);
//   }

//   void wifiSettings(String outputText) {
//     _ttsService.speak(outputText);
//     responseTextNotifier.value = outputText;
//     _settingsController.toggleWifi();
//   }

//   void hotspotSettings(String outputText) {
//     _ttsService.speak(outputText);
//     responseTextNotifier.value = outputText;
//     _settingsController.toggleHotspot();
//   }
// }

// class MobileBertNERTokenizer {
//   final Map<String, int> vocab;
//   final String clsToken;
//   final String sepToken;
//   final String padToken;
//   final String unkToken;
//   final int modelMaxLength;
//   final bool doLowerCase;

//   MobileBertNERTokenizer({
//     required this.vocab,
//     required this.clsToken,
//     required this.sepToken,
//     required this.padToken,
//     required this.unkToken,
//     this.modelMaxLength = 128,
//     this.doLowerCase = true,
//   });

//   List<int> tokenize(String text, {int? maxLength}) {
//     int seqLength = maxLength ?? modelMaxLength;
//     if (doLowerCase) {
//       text = text.toLowerCase();
//     }
//     // Use the same splitting logic as in tokenizeWithOffsets to mimic sub-token splitting.
//     RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
//     Iterable<RegExpMatch> matches = exp.allMatches(text);
//     List<int> tokenIds = [vocab[clsToken] ?? 101];

//     for (var match in matches) {
//       String word = match.group(0)!;
//       if (vocab.containsKey(word)) {
//         tokenIds.add(vocab[word]!);
//       } else {
//         tokenIds.add(vocab[unkToken] ?? 100);
//       }
//     }
//     tokenIds.add(vocab[sepToken] ?? 102);

//     if (tokenIds.length < seqLength) {
//       tokenIds +=
//           List.filled(seqLength - tokenIds.length, vocab[padToken] ?? 0);
//     } else {
//       tokenIds = tokenIds.sublist(0, seqLength);
//       tokenIds[seqLength - 1] = vocab[sepToken] ?? 102;
//     }
//     return tokenIds;
//   }

//   // Tokenizes the input text and returns token details including offsets.
//   List<Map<String, dynamic>> tokenizeWithOffsets(String text,
//       {int? maxLength}) {
//     int seqLength = maxLength ?? modelMaxLength;
//     String processedText = doLowerCase ? text.toLowerCase() : text;
//     List<Map<String, dynamic>> tokens = [];

//     // Add [CLS] token with dummy offsets.
//     tokens.add({
//       'token': clsToken,
//       'tokenId': vocab[clsToken] ?? 101,
//       'start': 0,
//       'end': 0,
//     });

//     // Use a regex to split text into digits, words, and punctuation.
//     RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
//     Iterable<RegExpMatch> matches = exp.allMatches(processedText);
//     for (final match in matches) {
//       String word = match.group(0)!;
//       int start = match.start;
//       int end = match.end;
//       int tokenId =
//           vocab.containsKey(word) ? vocab[word]! : (vocab[unkToken] ?? 100);
//       tokens.add({
//         'token': word,
//         'tokenId': tokenId,
//         'start': start,
//         'end': end,
//       });
//     }

//     // Add [SEP] token with dummy offsets.
//     tokens.add({
//       'token': sepToken,
//       'tokenId': vocab[sepToken] ?? 102,
//       'start': processedText.length,
//       'end': processedText.length,
//     });

//     // Pad tokens if necessary.
//     while (tokens.length < seqLength) {
//       tokens.add({
//         'token': padToken,
//         'tokenId': vocab[padToken] ?? 0,
//         'start': 0,
//         'end': 0,
//       });
//     }

//     // Truncate if necessary and ensure last token is [SEP].
//     if (tokens.length > seqLength) {
//       tokens = tokens.sublist(0, seqLength);
//       tokens[seqLength - 1] = {
//         'token': sepToken,
//         'tokenId': vocab[sepToken] ?? 102,
//         'start': processedText.length,
//         'end': processedText.length,
//       };
//     }

//     return tokens;
//   }
// }

// class NERService {
//   late Interpreter _interpreter;
//   late Map<int, String> entityMapping;
//   late MobileBertNERTokenizer tokenizer;
//   bool _isModelLoaded = false;

//   Future<void> loadModel() async {
//     _interpreter =
//         await Interpreter.fromAsset('assets/mobilebert-luna-ner/model.tflite');

//     // Load entity mapping from JSON.
//     String entityJsonStr = await rootBundle
//         .loadString('assets/mobilebert-luna-ner/intent_mapping.json');
//     Map<String, dynamic> entityJsonMap = json.decode(entityJsonStr);
//     entityMapping = entityJsonMap
//         .map((key, value) => MapEntry(int.parse(key), value as String));

//     // Load vocabulary from vocab.txt.
//     String vocabStr =
//         await rootBundle.loadString('assets/mobilebert-luna-ner/vocab.txt');
//     List<String> vocabLines = const LineSplitter().convert(vocabStr);
//     Map<String, int> vocab = {
//       for (int i = 0; i < vocabLines.length; i++) vocabLines[i]: i,
//     };

//     // Load tokenizer configuration from the extracted JSON.
//     String tokenizerConfigStr = await rootBundle
//         .loadString('assets/mobilebert-luna-ner/tokenizer_config.json');
//     Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);

//     tokenizer = MobileBertNERTokenizer(
//       vocab: vocab,
//       clsToken: tokenizerConfig['cls_token'] ?? "[CLS]",
//       sepToken: tokenizerConfig['sep_token'] ?? "[SEP]",
//       padToken: tokenizerConfig['pad_token'] ?? "[PAD]",
//       unkToken: tokenizerConfig['unk_token'] ?? "[UNK]",
//       modelMaxLength: 128, // You can adjust this if needed.
//       doLowerCase: tokenizerConfig['do_lower_case'] ?? true,
//     );

//     _isModelLoaded = true;
//     print("NER model and tokenizer loaded.");
//   }

//   Future<List<Map<String, dynamic>>> fetchEntities(String inputText) async {
//     if (!_isModelLoaded) {
//       await loadModel();
//     }

//     // Tokenize input and obtain token details (including offsets)
//     List<Map<String, dynamic>> tokenDetails =
//         tokenizer.tokenizeWithOffsets(inputText, maxLength: 128);
//     List<int> inputIds = tokenDetails.map((t) => t['tokenId'] as int).toList();
//     int padId = tokenizer.vocab[tokenizer.padToken] ?? 0;
//     List<int> attentionMask =
//         inputIds.map((id) => id == padId ? 0 : 1).toList();

//     Int32List inputIds32 = Int32List.fromList(inputIds);
//     Int32List mask32 = Int32List.fromList(attentionMask);

//     var inputTensor = [inputIds32];
//     var maskTensor = [mask32];

//     // Determine the model's output shape.
//     List<int> outputShape = _interpreter.getOutputTensor(0).shape;
//     int modelNumEntities = outputShape[2];

//     // Create the output tensor buffer.
//     var outputTensor = List.filled(1 * 128 * modelNumEntities, 0.0)
//         .reshape([1, 128, modelNumEntities]);

//     _interpreter
//         .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});

//     // Process the output logits for each token.
//     List<Map<String, dynamic>> results = [];
//     for (int i = 0; i < 128; i++) {
//       List<double> logits = List<double>.from(outputTensor[0][i]);
//       List<double> probs = softmax(logits);
//       int predictedIndex = argMax(logits);
//       double score = probs[predictedIndex];
//       String predictedEntity = (predictedIndex < modelNumEntities)
//           ? (entityMapping[predictedIndex] ?? "O")
//           : "O";

//       // Skip special tokens and tokens predicted as "O"
//       String tokenText = tokenDetails[i]['token'];
//       if (tokenText == tokenizer.clsToken ||
//           tokenText == tokenizer.sepToken ||
//           tokenText == tokenizer.padToken ||
//           predictedEntity == "O") {
//         continue;
//       }

//       results.add({
//         "word": tokenText,
//         "score": score,
//         "entity": predictedEntity,
//         "index": i,
//         "start": tokenDetails[i]['start'],
//         "end": tokenDetails[i]['end'],
//       });
//     }

//     return results;
//   }

//   double _exp(double x) => math.exp(x);

//   List<double> softmax(List<double> logits) {
//     double maxLogit = logits.reduce(math.max);
//     List<double> exps = logits.map((x) => _exp(x - maxLogit)).toList();
//     double sumExps = exps.reduce((a, b) => a + b);
//     return exps.map((e) => e / sumExps).toList();
//   }

//   int argMax(List<double> list) {
//     double maxValue = list[0];
//     int maxIndex = 0;
//     for (int i = 1; i < list.length; i++) {
//       if (list[i] > maxValue) {
//         maxValue = list[i];
//         maxIndex = i;
//       }
//     }
//     return maxIndex;
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // for compute()
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:luna/presentation/home/services/tts_service.dart';
import 'package:luna/services/settings_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// MobileBertTokenizer replicates the Hugging Face MobileBertTokenizer’s basic tokenization:
/// - Lowercases input (do_lower_case=true)
/// - Splits text into words, numbers, and punctuation using regex
/// - Inserts special tokens [CLS] at the beginning and [SEP] at the end
/// - Pads/truncates to a fixed maxLength
class MobileBertTokenizer {
  final Map<String, int> vocab;
  final String clsToken;
  final String sepToken;
  final String padToken;
  final String unkToken;

  MobileBertTokenizer({
    required this.vocab,
    required this.clsToken,
    required this.sepToken,
    required this.padToken,
    required this.unkToken,
  });

  List<int> tokenize(String text, {int maxLength = 128}) {
    // Lowercase as configured
    text = text.toLowerCase();
    // Use regex to split into words, digits, and punctuation
    final RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
    final Iterable<RegExpMatch> matches = exp.allMatches(text);
    List<int> tokenIds = [];
    // Prepend the CLS token
    tokenIds.add(vocab[clsToken] ?? 101);
    for (final match in matches) {
      String word = match.group(0)!;
      if (vocab.containsKey(word)) {
        tokenIds.add(vocab[word]!);
      } else {
        tokenIds.add(vocab[unkToken] ?? 100);
      }
    }
    // Append the SEP token
    tokenIds.add(vocab[sepToken] ?? 102);
    // Pad or truncate to maxLength
    if (tokenIds.length < maxLength) {
      tokenIds +=
          List.filled(maxLength - tokenIds.length, vocab[padToken] ?? 0);
    } else if (tokenIds.length > maxLength) {
      tokenIds = tokenIds.sublist(0, maxLength);
      tokenIds[maxLength - 1] = vocab[sepToken] ?? 102;
    }
    return tokenIds;
  }
}

/// MobileBertNERTokenizer works similarly and also returns token offsets for NER.
class MobileBertNERTokenizer {
  final Map<String, int> vocab;
  final String clsToken;
  final String sepToken;
  final String padToken;
  final String unkToken;
  final int modelMaxLength;
  final bool doLowerCase;

  MobileBertNERTokenizer({
    required this.vocab,
    required this.clsToken,
    required this.sepToken,
    required this.padToken,
    required this.unkToken,
    this.modelMaxLength = 128,
    this.doLowerCase = true,
  });

  List<int> tokenize(String text, {int? maxLength}) {
    int seqLength = maxLength ?? modelMaxLength;
    if (doLowerCase) {
      text = text.toLowerCase();
    }
    final RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
    Iterable<RegExpMatch> matches = exp.allMatches(text);
    List<int> tokenIds = [vocab[clsToken] ?? 101];
    for (final match in matches) {
      String word = match.group(0)!;
      if (vocab.containsKey(word)) {
        tokenIds.add(vocab[word]!);
      } else {
        tokenIds.add(vocab[unkToken] ?? 100);
      }
    }
    tokenIds.add(vocab[sepToken] ?? 102);
    if (tokenIds.length < seqLength) {
      tokenIds +=
          List.filled(seqLength - tokenIds.length, vocab[padToken] ?? 0);
    } else {
      tokenIds = tokenIds.sublist(0, seqLength);
      tokenIds[seqLength - 1] = vocab[sepToken] ?? 102;
    }
    return tokenIds;
  }

  List<Map<String, dynamic>> tokenizeWithOffsets(String text,
      {int? maxLength}) {
    int seqLength = maxLength ?? modelMaxLength;
    String processedText = doLowerCase ? text.toLowerCase() : text;
    List<Map<String, dynamic>> tokens = [];
    // CLS token with dummy offsets
    tokens.add({
      'token': clsToken,
      'tokenId': vocab[clsToken] ?? 101,
      'start': 0,
      'end': 0,
    });
    final RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
    Iterable<RegExpMatch> matches = exp.allMatches(processedText);
    for (final match in matches) {
      String word = match.group(0)!;
      int start = match.start;
      int end = match.end;
      int tokenId =
          vocab.containsKey(word) ? vocab[word]! : (vocab[unkToken] ?? 100);
      tokens.add({
        'token': word,
        'tokenId': tokenId,
        'start': start,
        'end': end,
      });
    }
    tokens.add({
      'token': sepToken,
      'tokenId': vocab[sepToken] ?? 102,
      'start': processedText.length,
      'end': processedText.length,
    });
    while (tokens.length < seqLength) {
      tokens.add({
        'token': padToken,
        'tokenId': vocab[padToken] ?? 0,
        'start': 0,
        'end': 0,
      });
    }
    if (tokens.length > seqLength) {
      tokens = tokens.sublist(0, seqLength);
      tokens[seqLength - 1] = {
        'token': sepToken,
        'tokenId': vocab[sepToken] ?? 102,
        'start': processedText.length,
        'end': processedText.length,
      };
    }
    return tokens;
  }
}

/// Top-level function to perform intent inference in an isolate.
/// Model bytes are passed in from the main isolate to avoid binding issues.
Future<Map<String, dynamic>> _runIntentInference(
    Map<String, dynamic> args) async {
  final interpreterOptions = InterpreterOptions();
  // In the isolate we create the interpreter from model bytes.
  Uint8List modelBytes = args['modelBytes'];
  Interpreter interpreter =
      Interpreter.fromBuffer(modelBytes, options: interpreterOptions);
  List<Int32List> inputTensor = List<Int32List>.from(args['inputTensor']);
  List<Int32List> maskTensor = List<Int32List>.from(args['maskTensor']);
  int numClasses = args['numClasses'];
  var outputTensor = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
  interpreter
      .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});
  interpreter.close();
  List<double> logits = List<double>.from(outputTensor[0]);
  return {'logits': logits};
}

/// OfflineService for intent classification.
class OfflineService {
  late Interpreter _interpreter;
  late Map<int, String> intentMapping;
  late MobileBertTokenizer tokenizer;
  bool _isModelLoaded = false;

  final SettingsController _settingsController = SettingsController();
  final TtsService _ttsService = TtsService();
  ValueNotifier<String> responseTextNotifier = ValueNotifier("");

  OfflineService({required this.responseTextNotifier});

  final SmsQuery query = SmsQuery();

  Future<void> loadModel() async {
    // Load the model using the asset file.
    final interpreterOptions = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/mobilebert-luna/model.tflite',
      options: interpreterOptions,
    );
    // Load intent mapping.
    String intentJsonStr = await rootBundle
        .loadString('assets/mobilebert-luna/intent_mapping.json');
    Map<String, dynamic> intentJsonMap = json.decode(intentJsonStr);
    intentMapping = intentJsonMap
        .map((key, value) => MapEntry(int.parse(key), value as String));
    // Load vocabulary.
    String vocabStr =
        await rootBundle.loadString('assets/mobilebert-luna/vocab.txt');
    List<String> vocabLines = const LineSplitter().convert(vocabStr);
    Map<String, int> vocab = {};
    for (int i = 0; i < vocabLines.length; i++) {
      vocab[vocabLines[i]] = i;
    }
    // Load tokenizer configuration (and special tokens come from tokenizer_config.json and special_tokens_map.json).
    String tokenizerConfigStr = await rootBundle
        .loadString('assets/mobilebert-luna/tokenizer_config.json');
    Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);
    // For MobileBert, the special tokens are defined in the config.
    String clsToken = tokenizerConfig['cls_token'] ?? "[CLS]";
    String sepToken = tokenizerConfig['sep_token'] ?? "[SEP]";
    String padToken = tokenizerConfig['pad_token'] ?? "[PAD]";
    String unkToken = tokenizerConfig['unk_token'] ?? "[UNK]";
    tokenizer = MobileBertTokenizer(
      vocab: vocab,
      clsToken: clsToken,
      sepToken: sepToken,
      padToken: padToken,
      unkToken: unkToken,
    );
    _isModelLoaded = true;
    log("Intent model, mapping, and tokenizer loaded.");
  }

  Future<String> fetchIntent(String inputText) async {
    if (!_isModelLoaded) await loadModel();
    List<int> inputIds = tokenizer.tokenize(inputText, maxLength: 128);
    int padId = tokenizer.vocab[tokenizer.padToken] ?? 0;
    List<int> attentionMask =
        inputIds.map((id) => id == padId ? 0 : 1).toList();
    Int32List inputIds32 = Int32List.fromList(inputIds);
    Int32List mask32 = Int32List.fromList(attentionMask);
    var inputTensor = [inputIds32];
    var maskTensor = [mask32];
    int numClasses = intentMapping.length;
    // Pre-load the model bytes from the main isolate.
    ByteData modelData =
        await rootBundle.load('assets/mobilebert-luna/model.tflite');
    Uint8List modelBytes = modelData.buffer.asUint8List();
    Map<String, dynamic> args = {
      'modelBytes': modelBytes,
      'inputTensor': inputTensor,
      'maskTensor': maskTensor,
      'numClasses': numClasses,
    };
    final result = await compute(_runIntentInference, args);
    List<double> logits = List<double>.from(result['logits']);
    List<double> probabilities = softmax(logits);
    int predictedIndex = argMax(probabilities);
    String predictedIntent = intentMapping[predictedIndex] ?? "Unknown";
    double confidence = probabilities[predictedIndex];
    log("Intent: $predictedIntent (Confidence: ${(confidence * 100).toStringAsFixed(2)}%)");
    return predictedIntent;
  }

  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce(math.max);
    List<double> exps = logits.map((e) => math.exp(e - maxLogit)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  int argMax(List<double> list) {
    double maxValue = list[0];
    int maxIndex = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    log("Max value: $maxValue");
    return maxIndex;
  }

  Future<void> processIntent(String intent, List<Map<String, dynamic>> results,
      String textData) async {
    textData = textData.toLowerCase();
    if (intent == "iot_hue_lightdim" || intent == "iot_hue_lighton") {
      if (textData.contains("flashlight")) {
        toggleFlashLight(true);
      } else if (textData.contains("brightness")) {
        String outputText = "Screen brightness decreased";
        _ttsService.speak(outputText);
        responseTextNotifier.value = outputText;
        _settingsController.decreaseBrightness();
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
    } else if (intent == "iot_hue_lightoff") {
      toggleFlashLight(false);
    } else if (textData.contains("turn on") || textData.contains("enable")) {
      log("turn on settings");
      String word = results.fold(
          "", (prev, element) => prev + (element['word'].trim().toLowerCase()));
      if (textData.contains("hotspot")) {
        hotspotSettings("Opening Hotspot Settings");
      } else if (word == 'wifi' || textData.contains("wi-fi")) {
        wifiSettings("Please Turn On Wifi");
      } else if (word == 'bluetooth' || textData.contains("bluetooth")) {
        bluetoothSettings("Turning on Bluetooth", true);
      } else if (textData.contains("mobile data")) {
        mobileDataSettings("Opening mobile data settings");
      } else {
        unclearInstruction();
      }
    } else if (intent == "iot_wemo_off") {
      String word = results.fold(
          "", (prev, element) => prev + (element['word'].trim().toLowerCase()));
      if (textData.contains("turn on") || textData.contains("enable")) {
        if (textData.contains("hotspot")) {
          hotspotSettings("Opening Hotspot Settings");
        } else if (word == 'wifi' || textData.contains("wi-fi")) {
          wifiSettings("Please Turn On Wifi");
        } else if (word == 'bluetooth') {
          bluetoothSettings("Turning on Bluetooth", true);
        } else if (textData.contains("mobile data")) {
          mobileDataSettings("Opening mobile data settings");
        } else {
          unclearInstruction();
        }
      }
      if (textData.contains("hotspot")) {
        hotspotSettings("Opening Hotspot Settings");
      } else if (word == 'bluetooth' || textData.contains("bluetooth")) {
        bluetoothSettings("Turning off Bluetooth", false);
      } else if (word == 'wifi' || textData.contains("wi-fi")) {
        wifiSettings("Please turn off wifi");
      } else if (textData.contains("mobile data")) {
        mobileDataSettings("Opening mobile data settings");
      } else {
        unclearInstruction();
      }
    } else if (intent == 'audio_volume_mute') {
      audioVolumeMute();
    } else if (intent == 'audio_volume_up') {
      audioVolumeMax();
    } else if (intent == 'audio_volume_down' ||
        (textData.contains("volume") && textData.contains("reduce"))) {
      audioVolumeReduce();
    } else if (textData.contains("call")) {
      if (results.isNotEmpty) {
        String? contactName;
        for (var model in results) {
          if (model['entity'] == "B-person" ||
              model['entity'] == "I-person" ||
              model['entity'] == "B-relation" ||
              model['entity'] == "B-business_name") {
            contactName = (contactName ?? '') + (model['word']!.trim()) + (" ");
          }
        }
        if (contactName != null) {
          contactName = contactName.substring(0, contactName.length - 1);
        }
        log(contactName!);
        getContactDetails(contactName);
      } else {
        String errorText = "Please tell me who to call?";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
      }
    } else if (textData.contains("text") || textData.contains("text message")) {
      String errorText;
      if (results.isNotEmpty) {
        String? contactName;
        for (var model in results) {
          if (model['entity'] == "B-person" ||
              model['entity'] == "I-person" ||
              model['entity'] == "B-relation") {
            contactName = (contactName ?? "") + model['word'].trim() + (" ");
          }
        }
        contactName = contactName!.substring(0, contactName.length - 1);
        log(contactName);
        sendTextMessage(contactName, "");
      } else {
        errorText = "Please tell me who to text?";
        _ttsService.speak(errorText);
        responseTextNotifier.value = errorText;
      }
    } // Read Message
    else if (intent == "email_query" && textData.contains("read")) {
      String outputText;
      outputText = "Loading messages hang-tight!";
      _ttsService.speak(outputText);
      List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      );

      messages.sort((a, b) => b.date!.compareTo(a.date!));

      outputText = "";
      responseTextNotifier.value = outputText;

      for (int i = 0; i < 3; i++) {
        outputText =
            "\n" + messages[i].address! + " : \n\n${messages[i].body}\n";
        responseTextNotifier.value = outputText;
        responseTextNotifier.notifyListeners();
        _ttsService.speak(
            "message from ${messages[i].address!} saying that + ${messages[i].body}");
        log("${messages[i].address} ${messages[i].body}");
        await Future.delayed(Duration(seconds: messages[i].body!.length ~/ 8));
      }
    }
  }

  Future<List<Contact>> fetchContacts() async {
    return await FlutterContacts.getContacts(withProperties: true);
  }

  Future<void> requestSmsPermission() async {
    var status = await Permission.sms.status;

    if (status.isDenied) {
      await Permission.sms.request();
    }

    if (await Permission.sms.isGranted) {
      log("SMS permission granted.");
    } else {
      log("SMS permission denied.");
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
      String successText = "Send text to ${matchingNames[0]}.";
      await _ttsService.flutterTts.speak(successText);
      responseTextNotifier.value = successText;
      sendSMS(phoneNumbers[0].number, "");
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

  // Device control methods remain unchanged:
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

  void audioVolumeReduce() {
    _settingsController.toggleAudioDown();
    _ttsService.speak("volume reduced");
  }

  void audioVolumeMax() {
    String outputText = "Volume set to full";
    _settingsController.toggleAudioFull();
    _ttsService.speak(outputText);
  }

  void unclearInstruction() {
    String outputText = "Sorry, I didn't quite catch that";
    _ttsService.speak(outputText);
    responseTextNotifier.value = outputText;
  }

  void audioVolumeMute() {
    String outputText = "Muting audio";
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

/// Top-level function to perform NER inference in an isolate.
/// Uses model bytes passed from the main isolate.
Future<Map<String, dynamic>> _runNERInference(Map<String, dynamic> args) async {
  final interpreterOptions = InterpreterOptions();
  Uint8List modelBytes = args['modelBytes'];
  Interpreter interpreter =
      Interpreter.fromBuffer(modelBytes, options: interpreterOptions);
  List<Int32List> inputTensor = List<Int32List>.from(args['inputTensor']);
  List<Int32List> maskTensor = List<Int32List>.from(args['maskTensor']);
  int modelNumEntities = args['modelNumEntities'];
  var outputTensor = List.filled(1 * 128 * modelNumEntities, 0.0)
      .reshape([1, 128, modelNumEntities]);
  interpreter
      .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});
  interpreter.close();
  return {'outputTensor': outputTensor};
}

/// NERService for Named Entity Recognition.
class NERService {
  late Interpreter _interpreter;
  late Map<int, String> entityMapping;
  late MobileBertNERTokenizer tokenizer;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    final interpreterOptions = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/mobilebert-luna-ner/model.tflite',
      options: interpreterOptions,
    );
    String entityJsonStr = await rootBundle
        .loadString('assets/mobilebert-luna-ner/intent_mapping.json');
    Map<String, dynamic> entityJsonMap = json.decode(entityJsonStr);
    entityMapping = entityJsonMap
        .map((key, value) => MapEntry(int.parse(key), value as String));
    String vocabStr =
        await rootBundle.loadString('assets/mobilebert-luna-ner/vocab.txt');
    List<String> vocabLines = const LineSplitter().convert(vocabStr);
    Map<String, int> vocab = {
      for (int i = 0; i < vocabLines.length; i++) vocabLines[i]: i
    };
    String tokenizerConfigStr = await rootBundle
        .loadString('assets/mobilebert-luna-ner/tokenizer_config.json');
    Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);
    // Use the same special tokens from the tokenizer config.
    String clsToken = tokenizerConfig['cls_token'] ?? "[CLS]";
    String sepToken = tokenizerConfig['sep_token'] ?? "[SEP]";
    String padToken = tokenizerConfig['pad_token'] ?? "[PAD]";
    String unkToken = tokenizerConfig['unk_token'] ?? "[UNK]";
    tokenizer = MobileBertNERTokenizer(
      vocab: vocab,
      clsToken: clsToken,
      sepToken: sepToken,
      padToken: padToken,
      unkToken: unkToken,
      modelMaxLength: 128,
      doLowerCase: tokenizerConfig['do_lower_case'] ?? true,
    );
    _isModelLoaded = true;
    log("NER model and tokenizer loaded.");
  }

  Future<List<Map<String, dynamic>>> fetchEntities(String inputText) async {
    if (!_isModelLoaded) await loadModel();
    List<Map<String, dynamic>> tokenDetails =
        tokenizer.tokenizeWithOffsets(inputText, maxLength: 128);
    List<int> inputIds = tokenDetails.map((t) => t['tokenId'] as int).toList();
    int padId = tokenizer.vocab[tokenizer.padToken] ?? 0;
    List<int> attentionMask =
        inputIds.map((id) => id == padId ? 0 : 1).toList();
    Int32List inputIds32 = Int32List.fromList(inputIds);
    Int32List mask32 = Int32List.fromList(attentionMask);
    var inputTensor = [inputIds32];
    var maskTensor = [mask32];
    List<int> outputShape = _interpreter.getOutputTensor(0).shape;
    int modelNumEntities = outputShape[2];
    ByteData modelData =
        await rootBundle.load('assets/mobilebert-luna-ner/model.tflite');
    Uint8List modelBytes = modelData.buffer.asUint8List();
    Map<String, dynamic> args = {
      'modelBytes': modelBytes,
      'inputTensor': inputTensor,
      'maskTensor': maskTensor,
      'modelNumEntities': modelNumEntities,
    };
    final result = await compute(_runNERInference, args);
    var outputTensor = result['outputTensor'] as List;
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < 128; i++) {
      List<double> logits = List<double>.from(outputTensor[0][i]);
      List<double> probs = softmax(logits);
      int predictedIndex = argMax(logits);
      double score = probs[predictedIndex];
      String predictedEntity = (predictedIndex < modelNumEntities)
          ? (entityMapping[predictedIndex] ?? "O")
          : "O";
      String tokenText = tokenDetails[i]['token'];
      if (tokenText == tokenizer.clsToken ||
          tokenText == tokenizer.sepToken ||
          tokenText == tokenizer.padToken ||
          predictedEntity == "O") continue;
      results.add({
        "word": tokenText,
        "score": score,
        "entity": predictedEntity,
        "index": i,
        "start": tokenDetails[i]['start'],
        "end": tokenDetails[i]['end'],
      });
    }
    return results;
  }

  double _exp(double x) => math.exp(x);
  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce(math.max);
    List<double> exps = logits.map((x) => _exp(x - maxLogit)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  int argMax(List<double> list) {
    double maxValue = list[0];
    int maxIndex = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }
}
