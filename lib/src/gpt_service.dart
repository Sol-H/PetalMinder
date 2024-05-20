import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_constants.dart';

class GPTService {
  final Dio _dio = Dio();

  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> sendMessageGPT({required String diseaseName}) async {
    try {
      final response = await _dio.post(
        "$OPENAI_BASE_URL/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $OPENAI_API_KEY',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: {
          "model": 'gpt-3.5-turbo',
          "messages": [
            {
              "role": "user",
              "content":
                  "GPT, when you receive the name of a plant disease and its percentage chance, provide three precautionary measures to prevent or manage the disease. If the chance is below 50%, just say 'The plant is healthy' These measures should be concise, clear, and limited to one sentence each. No additional information or context is needed—only the three precautions in bullet-point format, do not include the disease name. The disease is $diseaseName",
            }
          ],
        },
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      return jsonResponse["choices"][0]["message"]["content"];
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
