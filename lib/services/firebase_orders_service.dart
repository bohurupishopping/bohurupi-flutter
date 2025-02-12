import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FirebaseOrdersService {
  static const String apiKey = 'x84kjjfkdjk';
  static const String adminEmail = 'admin@bohurupi.com';
  static const String adminPassword = '33558822';
  
  // API URLs
  static const String _devBaseUrl = 'http://localhost:3000/api/firebase';
  static const String _prodBaseUrl = 'https://order.bohurupi.com/api/firebase';

  final bool isDev;

  FirebaseOrdersService({
    bool? isDev,
  }) : isDev = isDev ?? kDebugMode {
    // Debug log
  }

  String get _apiBaseUrl => isDev ? _devBaseUrl : _prodBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
    'Authorization': 'Basic ${base64Encode(utf8.encode('$adminEmail:$adminPassword'))}',
  };

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

      final uri = Uri.parse('$_apiBaseUrl/orders/completed').replace(queryParameters: queryParams);
      
      // Debug log
      
      final response = await http.get(uri, headers: _headers);

      // Debug log
      // Debug log

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
      // Debug log
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

      final uri = Uri.parse('$_apiBaseUrl/orders/pending').replace(queryParameters: queryParams);
      
      // Debug log
      
      final response = await http.get(uri, headers: _headers);

      // Debug log
      // Debug log

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
      // Debug log
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