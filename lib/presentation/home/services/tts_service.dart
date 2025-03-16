import 'dart:developer';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TtsService {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  SpeechService? voskSpeech;

  // initialise speech
  Future<bool> initSpeech() async {
    await speechToText.initialize();
    return true;
  }

  Future<void> initOfflineSpeech() async {
    await initializeOfflineSTT();
  }

  // initialise text to speech
  Future<void> initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
  }

  Future<void> stopOfflineSTT() async {
    if (voskSpeech != null) {
      await voskSpeech!.stop();
      voskSpeech = null;
      log('[Vosk] SpeechService stopped');
    }
  }

  // initialize offline speech to text
  Future<void> initializeOfflineSTT() async {
    if (voskSpeech != null) {
      log('[Vosk] Already initialized, reinitializing...');
      await stopOfflineSTT(); // 🛑 Stop previous instance
    }

    try {
      final vosk = VoskFlutterPlugin.instance();
      final modelPath = await ModelLoader()
          .loadFromAssets('assets/models/vosk-model-en-us-0.22-lgraph.zip');
      log('[Vosk] Model loaded at $modelPath');

      final model = await vosk.createModel(modelPath);
      final recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: 16000, // safer and more compatible
      );

      voskSpeech = await vosk.initSpeechService(recognizer);
      log('[Vosk] SpeechService initialized successfully');
    } catch (e, stackTrace) {
      log('[Vosk] Error during initialization: $e');
      log('[Vosk] StackTrace: $stackTrace');
    }
  }

  // TTS Speak Function
  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }
}
