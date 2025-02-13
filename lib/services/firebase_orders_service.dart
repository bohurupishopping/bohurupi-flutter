import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'environment_service.dart';

class FirebaseOrdersService {
  final EnvironmentService _env = EnvironmentService.instance;
  final String _endpoint = '/firebase';

  // Hardcoded admin credentials (previously in environment_service.dart)
  static const String _adminEmail = 'admin@bohurupi.com';
  static const String _adminPassword = '33558822';

  // Computed admin auth header based on hardcoded details
  String get _adminAuth =>
      'Basic ${base64.encode(utf8.encode('$_adminEmail:$_adminPassword'))}';

  // Hardcoded API Key (previously in environment_service.dart)
  static const String _apiKey = 'x84kjjfkdjk';

  String get _apiBaseUrl => '${_env.baseUrl}$_endpoint';

  // Fetch completed orders with pagination and search
  Future<Map<String, dynamic>> getCompletedOrders({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$_apiBaseUrl/orders/completed')
          .replace(queryParameters: queryParams);
      
      // Build headers with hardcoded admin auth
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey, // Using hardcoded API key
        'Authorization': _adminAuth,
      };

      if (kDebugMode) {
        print('GET Request: $uri');
        print('Headers: $headers');
      }
      
      final response = await http.get(uri, headers: headers);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch completed orders: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching completed orders: $e');
      }
      throw Exception('Failed to fetch completed orders: $e');
    }
  }

  // Fetch pending orders with pagination and search
  Future<Map<String, dynamic>> getPendingOrders({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$_apiBaseUrl/orders/pending')
          .replace(queryParameters: queryParams);
      
      // Build headers with hardcoded admin auth
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey, // Using hardcoded API key
        'Authorization': _adminAuth,
      };

      if (kDebugMode) {
        print('GET Request: $uri');
        print('Headers: $headers');
      }
      
      final response = await http.get(uri, headers: headers);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch pending orders: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pending orders: $e');
      }
      throw Exception('Failed to fetch pending orders: $e');
    }
  }
}

// Order Status Types
enum FirebaseOrderStatus {
  pending,
  completed;

  String get value {
    switch (this) {
      case FirebaseOrderStatus.pending:
        return 'pending';
      case FirebaseOrderStatus.completed:
        return 'completed';
    }
  }

  static FirebaseOrderStatus? fromString(String? status) {
    if (status == null) return null;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return FirebaseOrderStatus.pending;
      case 'completed':
        return FirebaseOrderStatus.completed;
      default:
        return null;
    }
  }
} 