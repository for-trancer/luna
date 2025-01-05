import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:luna/application/models/data/data_model.dart';
import 'package:luna/application/models/image/image_model.dart';
import 'package:luna/application/models/intents/intents_model.dart';
import 'package:luna/infrastructure/api_end_points.dart';
import 'package:luna/infrastructure/api_keys.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainService {
  final Dio dio = Dio();
  // Intent Identification
  Future<IntentsModel> fetchIntentPrediction(String userInput) async {
    String localhost = ApiEndPoints.localhost;
    String parameter = ApiEndPoints.intent;
    String url = '$localhost$parameter';

    final data = {
      "text": userInput,
    };

    try {
      final response = await dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.data is List) {
        // Assuming you want the first element of the list
        final list = response.data as List;
        if (response.data.isNotEmpty) {
          return IntentsModel.fromJson(list.first as Map<String, dynamic>);
        } else {
          throw Exception('Response list is empty');
        }
      } else if (response.data is Map<String, dynamic>) {
        return IntentsModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        log(response.data.runtimeType.toString());
        throw Exception(
            'Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to get intent : $e');
    }
  }

  // Text To Image Generation
  Future<ImageModel> fetchImage(String userInput) async {
    String url = '${ApiEndPoints.localhost}${ApiEndPoints.image}';

    final data = {
      "text": userInput,
    };

    try {
      final response = await http.post(
        Uri.parse(url), // Use Uri.parse to create a Uri object
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(data), // Encode the data to JSON
      );

      if (response.statusCode == 200) {
        // Check if the response is successful
        return ImageModel.fromJson(
            jsonDecode(response.body)); // Decode the response body
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch image: $e');
    }
  }

  // Named Entity Recognition
  Future<List<DataModel?>> fetchData(String userInput) async {
    String localhost = ApiEndPoints.localhost;
    String parameter = ApiEndPoints.data;
    String url = '$localhost$parameter';

    final data = {
      "text": userInput,
    };
    final response = await dio.post(
      url,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    log(response.data.toString());

    if (response.data != null && response.data.isNotEmpty) {
      // Assuming response.data is a list of entities
      List<DataModel> dataModels = (response.data as List)
          .map((item) => DataModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return dataModels;
    } else {
      // Return null or a default DataModel instance if the list is empty
      return []; // or return DataModel(); if you want to return a default instance
    }
  }

  // Open Ai Response
  Future<String?> fetchInformation(String prompt) async {
    try {
      final response = await dio.post(
        ApiEndPoints.openAI,
        options: Options(
          headers: {
            'Authorization': 'Bearer $openAiApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
          "max_tokens": 100,
        },
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        String data = response.data['choices'][0]['message']['content'];
        log(data);
        return data;
      } else {
        // Handle non-200 responses
        log('Error: ${response.statusCode} - ${response.statusMessage}');
        return null; // or return a default message
      }
    } catch (e) {
      // Handle Dio exceptions
      if (e is DioException) {
        log('Dio error: ${e.message}');
        if (e.response != null) {
          log('Response data: ${e.response?.data}');
          log('Response status: ${e.response?.statusCode}');
        }
      } else {
        log('Unexpected error: $e');
      }
      return null; // Return null on error
    }
  }
}
