import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_constants.dart';

class InfoApiService {
  final Dio _dio = Dio();

  Future<List<String>> getPlantList(String query) async {
    if (query == '') {
      return [];
    }
    try {
      final response = await _dio.get(
        "https://perenual.com/api/species-list?key=$PERENUAL_API_KEY&page=1&q=$query",
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );
      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final List<dynamic> dataList = jsonResponse["data"];
      final List<String> commonNames = [];
      for (var part in dataList) {
        commonNames.add(part["common_name"]);
      }
      return commonNames;
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<int> getPlantID({required String query}) async {
    try {
      final response = await _dio.get(
        "https://perenual.com/api/species-list?key=$PERENUAL_API_KEY&page=1&q=$query",
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );
      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final List<dynamic> dataList = jsonResponse["data"];
      final int speciesID = dataList[0]["id"];
      return speciesID;
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<String> getWateringInfo({required int speciesID}) async {
    String id = speciesID.toString();
    try {
      final response = await _dio.get(
        "https://perenual.com/api/species/details/$id?key=$PERENUAL_API_KEY",
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );
      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final Map<String, dynamic> dataList = jsonResponse["watering_general_benchmark"];
      final String frequency = dataList["value"] ?? "1";
      final String unit = dataList["unit"] ?? "month";
      final String message = "Water every $frequency $unit";
      return message;
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<String> getPlantImage({required int speciesID}) async {
    String id = speciesID.toString();
    try {
      final response = await _dio.get(
        "https://perenual.com/api/species/details/$id?key=$PERENUAL_API_KEY",
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );
      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final Map<String, dynamic> dataList = jsonResponse["default_image"] ?? {};
      final String imageUrl = dataList["medium_url"] ?? "";
      return imageUrl;
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Map<String, dynamic>> getPlantInfo({required int speciesID}) async {
    String id = speciesID.toString();
    try {
      final response = await _dio.get(
        "https://perenual.com/api/species/details/$id?key=$PERENUAL_API_KEY",
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );
      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final String description = jsonResponse["description"] ?? "No description available";
      final String growthRate = jsonResponse["growth_rate"] ?? "No growth rate available";
      final String sunlight = jsonResponse["sunlight"][0] ?? "No sunlight information available";
      final String careLevel = jsonResponse["care_level"]?? "No care level available";
      return {
        "description": description,
        "growth_rate": "$growthRate growth rate",
        "sunlight": "Sunlight: $sunlight",
        "care_level": "$careLevel care level",
      };
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
