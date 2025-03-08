import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
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

    // Convert the lists to Int32List, because the model expects int32.
    Int32List inputIds32 = Int32List.fromList(inputIds);
    Int32List mask32 = Int32List.fromList(attentionMask);

    // Create input tensors with shape [1, 128].
    var inputTensor = [inputIds32];
    var maskTensor = [mask32];

    // Prepare the output buffer with shape [1, numClasses].
    int numClasses = intentMapping.length;
    var outputTensor =
        List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    // Run inference synchronously.
    _interpreter
        .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});

    // Convert output tensor (logits) to a list of doubles.
    List<double> logits = List<double>.from(outputTensor[0]);
    List<double> probabilities = softmax(logits);

    // Get the index with the highest probability.
    int predictedIndex = argMax(probabilities);
    String predictedIntent = intentMapping[predictedIndex] ?? "Unknown";
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

  // Process Intent (placeholder for further functionality)
  void processIntent(String intent, String textData) {
    // Implement your action logic here.
  }
}

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
    // Use the same splitting logic as in tokenizeWithOffsets to mimic sub-token splitting.
    RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
    Iterable<RegExpMatch> matches = exp.allMatches(text);
    List<int> tokenIds = [vocab[clsToken] ?? 101];

    for (var match in matches) {
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

  // Tokenizes the input text and returns token details including offsets.
  List<Map<String, dynamic>> tokenizeWithOffsets(String text,
      {int? maxLength}) {
    int seqLength = maxLength ?? modelMaxLength;
    String processedText = doLowerCase ? text.toLowerCase() : text;
    List<Map<String, dynamic>> tokens = [];

    // Add [CLS] token with dummy offsets.
    tokens.add({
      'token': clsToken,
      'tokenId': vocab[clsToken] ?? 101,
      'start': 0,
      'end': 0,
    });

    // Use a regex to split text into digits, words, and punctuation.
    RegExp exp = RegExp(r'(\d+|\w+|[^\w\s])');
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

    // Add [SEP] token with dummy offsets.
    tokens.add({
      'token': sepToken,
      'tokenId': vocab[sepToken] ?? 102,
      'start': processedText.length,
      'end': processedText.length,
    });

    // Pad tokens if necessary.
    while (tokens.length < seqLength) {
      tokens.add({
        'token': padToken,
        'tokenId': vocab[padToken] ?? 0,
        'start': 0,
        'end': 0,
      });
    }

    // Truncate if necessary and ensure last token is [SEP].
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

class NERService {
  late Interpreter _interpreter;
  late Map<int, String> entityMapping;
  late MobileBertNERTokenizer tokenizer;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/mobilebert-luna-ner/model.tflite');

    // Load entity mapping from JSON.
    String entityJsonStr = await rootBundle
        .loadString('assets/mobilebert-luna-ner/intent_mapping.json');
    Map<String, dynamic> entityJsonMap = json.decode(entityJsonStr);
    entityMapping = entityJsonMap
        .map((key, value) => MapEntry(int.parse(key), value as String));

    // Load vocabulary from vocab.txt.
    String vocabStr =
        await rootBundle.loadString('assets/mobilebert-luna-ner/vocab.txt');
    List<String> vocabLines = const LineSplitter().convert(vocabStr);
    Map<String, int> vocab = {
      for (int i = 0; i < vocabLines.length; i++) vocabLines[i]: i,
    };

    // Load tokenizer configuration from the extracted JSON.
    String tokenizerConfigStr = await rootBundle
        .loadString('assets/mobilebert-luna-ner/tokenizer_config.json');
    Map<String, dynamic> tokenizerConfig = json.decode(tokenizerConfigStr);

    tokenizer = MobileBertNERTokenizer(
      vocab: vocab,
      clsToken: tokenizerConfig['cls_token'] ?? "[CLS]",
      sepToken: tokenizerConfig['sep_token'] ?? "[SEP]",
      padToken: tokenizerConfig['pad_token'] ?? "[PAD]",
      unkToken: tokenizerConfig['unk_token'] ?? "[UNK]",
      modelMaxLength: 128, // You can adjust this if needed.
      doLowerCase: tokenizerConfig['do_lower_case'] ?? true,
    );

    _isModelLoaded = true;
    print("NER model and tokenizer loaded.");
  }

  Future<List<Map<String, dynamic>>> fetchEntities(String inputText) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    // Tokenize input and obtain token details (including offsets)
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

    // Determine the model's output shape.
    List<int> outputShape = _interpreter.getOutputTensor(0).shape;
    int modelNumEntities = outputShape[2];

    // Create the output tensor buffer.
    var outputTensor = List.filled(1 * 128 * modelNumEntities, 0.0)
        .reshape([1, 128, modelNumEntities]);

    _interpreter
        .runForMultipleInputs([inputTensor, maskTensor], {0: outputTensor});

    // Process the output logits for each token.
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < 128; i++) {
      List<double> logits = List<double>.from(outputTensor[0][i]);
      List<double> probs = softmax(logits);
      int predictedIndex = argMax(logits);
      double score = probs[predictedIndex];
      String predictedEntity = (predictedIndex < modelNumEntities)
          ? (entityMapping[predictedIndex] ?? "O")
          : "O";

      // Skip special tokens and tokens predicted as "O"
      String tokenText = tokenDetails[i]['token'];
      if (tokenText == tokenizer.clsToken ||
          tokenText == tokenizer.sepToken ||
          tokenText == tokenizer.padToken ||
          predictedEntity == "O") {
        continue;
      }

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
