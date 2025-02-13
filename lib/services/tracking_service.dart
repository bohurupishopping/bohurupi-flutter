import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/tracking_data.dart';
import 'environment_service.dart';

class TrackingService {
  final EnvironmentService _env = EnvironmentService.instance;
  final String _endpoint = '/tracking';

  String get _apiBaseUrl => '${_env.baseUrl}$_endpoint';

  Future<TrackingData> getTrackingInfo(String trackingId) async {
    try {
      final queryParams = {
        'waybill': trackingId,
      };

      final uri = Uri.parse(_apiBaseUrl).replace(queryParameters: queryParams);
      
      if (kDebugMode) {
        print('GET Request: $uri');
        print('Headers: ${_env.headersWithoutAuth}');
      }
      
      final response = await http.get(uri, headers: _env.headersWithoutAuth);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

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
      if (kDebugMode) {
        print('Error fetching tracking information: $e');
      }
      throw Exception('Failed to fetch tracking information: $e');
    }
  }
} 