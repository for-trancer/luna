import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TtsService {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  // initialise speech
  Future<void> initSpeech() async {
    await speechToText.initialize();
  }

  // initialise text to speech
  Future<void> initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
  }

  // TTS Speak Function
  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }
}
