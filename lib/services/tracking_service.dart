import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/tracking_data.dart';

class TrackingService {
  static const String apiKey = 'x84kjjfkdjk';
  
  // API URLs
  static const String _devBaseUrl = 'http://localhost:3000/api';
  static const String _prodBaseUrl = 'https://order.bohurupi.com/api';

  final bool isDev;

  TrackingService({
    bool? isDev,
  }) : isDev = isDev ?? kDebugMode; // Use kDebugMode as default if isDev is not provided

  String get _apiBaseUrl => isDev ? _devBaseUrl : _prodBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  Future<TrackingData> getTrackingInfo(String trackingId) async {
    try {
      final queryParams = {
        'waybill': trackingId,
      };

      final uri = Uri.parse('$_apiBaseUrl/tracking').replace(queryParameters: queryParams);
      
      // Debug log
      // Debug log for environment
      
      final response = await http.get(uri, headers: _headers);

      // Debug log
      // Debug log

      if (response.statusCode == 200) {
        return TrackingData.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Tracking information not found');
      } else {
        throw Exception('Failed to fetch tracking information: ${response.statusCode}');
      }
    } catch (e) {
      // Debug log
      throw Exception('Failed to fetch tracking information: $e');
    }
  }
} 