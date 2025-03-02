import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// A simple MobileBERT tokenizer that loads vocabulary and configuration
/// from assets.
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

  /// Tokenizes [text] by lowercasing and splitting on whitespace.
  /// It looks up each token in the vocabulary. For simplicity, this example
  /// does not implement full subword (WordPiece) tokenization.
  /// It prepends the [CLS] token and appends the [SEP] token, and pads
  /// the sequence to [maxLength].

  List<int> tokenize(String text, {int maxLength = 128}) {
    text = text.toLowerCase();
    // Basic whitespace splitting
    List<String> words = text.split(RegExp(r'\s+'));

    List<int> tokenIds = [];
    // Add the [CLS] token.
    tokenIds.add(vocab[clsToken] ?? 101);
    for (var word in words) {
      // Check if the word exists in the vocabulary.
      // For production, use a proper subword algorithm.
      if (vocab.containsKey(word)) {
        tokenIds.add(vocab[word]!);
      } else {
        tokenIds.add(vocab[unkToken] ?? 100);
      }
    }
    // Add the [SEP] token.
    tokenIds.add(vocab[sepToken] ?? 102);

    // Pad the sequence up to maxLength
    if (tokenIds.length < maxLength) {
      tokenIds +=
          List.filled(maxLength - tokenIds.length, vocab[padToken] ?? 0);
    } else if (tokenIds.length > maxLength) {
      // Truncate the sequence and ensure [SEP] is at the end.
      tokenIds = tokenIds.sublist(0, maxLength);
      tokenIds[maxLength - 1] = vocab[sepToken] ?? 102;
    }
    return tokenIds;
  }
}

class OfflineService {
  late Interpreter _interpreter;
  late Map<int, String> intentMapping;
  late MobileBertTokenizer tokenizer;
  bool _isModelLoaded = false; // Flag to track model loading

  /// Loads the TFLite model, intent mapping, vocabulary, and tokenizer configuration.
  Future<void> loadModel() async {
    // Load the TFLite model.
    _interpreter =
        await Interpreter.fromAsset('assets/mobilebert-luna/model.tflite');

    // Load intent mapping from JSON.
    String intentJsonStr = await rootBundle
        .loadString('assets/mobilebert-luna/intent_mapping.json');
    Map<String, dynamic> intentJsonMap = json.decode(intentJsonStr);
    intentMapping = intentJsonMap
        .map((key, value) => MapEntry(int.parse(key), value as String));

    // Load vocabulary from vocab.txt (one token per line).
    String vocabStr =
        await rootBundle.loadString('assets/mobilebert-luna/vocab.txt');
    List<String> vocabLines = const LineSplitter().convert(vocabStr);
    Map<String, int> vocab = {};
    for (int i = 0; i < vocabLines.length; i++) {
      vocab[vocabLines[i]] = i;
    }

    // Load tokenizer configuration.
    String tokenizerConfigStr = await rootBundle
        .loadString('assets/mobilebert-luna/tokenizer_config.json');
    Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);

    // Retrieve special tokens from the configuration.
    String clsToken = tokenizerConfig['cls_token'] ?? "[CLS]";
    String sepToken = tokenizerConfig['sep_token'] ?? "[SEP]";
    String padToken = tokenizerConfig['pad_token'] ?? "[PAD]";
    String unkToken = tokenizerConfig['unk_token'] ?? "[UNK]";

    // Create an instance of MobileBertTokenizer.
    tokenizer = MobileBertTokenizer(
      vocab: vocab,
      clsToken: clsToken,
      sepToken: sepToken,
      padToken: padToken,
      unkToken: unkToken,
    );

    _isModelLoaded = true;
    log("Model, intent mapping, and tokenizer loaded.");
  }

  /// Processes [inputText] by tokenizing it, running inference, and returning
  /// the predicted intent.
  Future<String> fetchIntent(String inputText) async {
    // Ensure the model is loaded.
    if (!_isModelLoaded) {
      await loadModel();
    }

    // Tokenize the input text.
    List<int> inputIds = tokenizer.tokenize(inputText, maxLength: 128);

    // Create an attention mask: 1 for non-[PAD] tokens, 0 for padding tokens.
    int padId = tokenizer.vocab[tokenizer.padToken] ?? 0;
    List<int> attentionMask =
        inputIds.map((id) => id == padId ? 0 : 1).toList();

    // Create input tensors with shape [1, 128].
    var inputTensor = [inputIds];
    var maskTensor = [attentionMask];

    log("\nInput tensor: $inputTensor");
    log("\nMask tensor: $maskTensor");

    // Prepare the output buffer with shape [1, numClasses].
    int numClasses = intentMapping.length;
    var outputTensor =
        List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    log("\nOutput tensor before inference: $outputTensor");

    // Run inference synchronously.
    _interpreter
        .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});

    // Convert output tensor (logits) to a list of doubles.
    List<double> logits = List<double>.from(outputTensor[0]);
    List<double> probabilities = softmax(logits);

    log("\nLogits: $logits");
    log("\nProbabilities: $probabilities");

    // Get the index with the highest probability.
    int predictedIndex = argMax(probabilities);
    String predictedIntent = intentMapping[predictedIndex] ?? "Unknown";

    log("\nPredicted index: $predictedIndex");
    double confidence = probabilities[predictedIndex];
    log("\nIntent: $predictedIntent (Confidence: ${(confidence * 100).toStringAsFixed(2)}%)");

    return predictedIntent;
  }

  /// Computes softmax for the list of logits.
  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce(math.max);
    List<double> exps = logits.map((e) => math.exp(e - maxLogit)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  /// Returns the index of the maximum value in the list.
  int argMax(List<double> list) {
    double maxValue = list[0];
    int maxIndex = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    log("\nMax value: $maxValue");
    return maxIndex;
  }
}
