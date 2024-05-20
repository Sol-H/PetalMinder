import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_constants.dart';

class DiseaseApiService {
  final Dio _dio = Dio();

  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> sendImageToPlantId({
    required File image,
  }) async {
    final String base64Image = await encodeImage(image);
    try {
      final response = await _dio.post(
        "https://plant.id/api/v3/health_assessment",
        options: Options(
          headers: {
            'Api-Key': PLANTID_API_KEY,
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: jsonEncode({
          'images': [
            'data:image/jpg;base64,$base64Image',
          ],
          "latitude": 49.207,
          "longitude": 16.608,
          "similar_images": true
        }),
      );

      final jsonResponse = response.data;

      final String disease =
          '${jsonResponse['result']['disease']['suggestions'][0]['probability']}% chance of ${jsonResponse['result']['disease']['suggestions'][0]['name']}';
      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }
      return disease;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
