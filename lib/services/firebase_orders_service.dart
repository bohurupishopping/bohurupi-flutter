import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'environment_service.dart';

/// Service for interacting with Firebase orders through the Admin SDK backend
class FirebaseOrdersService {
  final EnvironmentService _env = EnvironmentService.instance;
  final String _endpoint = '/firebase';

  String get _apiBaseUrl => '${_env.baseUrl}$_endpoint';

  /// Fetch completed orders with pagination and search
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
      
      if (kDebugMode) {
        print('GET Request: $uri');
        print('Headers: ${_env.headers}');
      }
      
      final response = await http.get(uri, headers: _env.headers);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _validateOrderResponse(data);
        return data;
      } else if (response.statusCode == 401) {
        _env.clearAuthToken(); // Clear cached token on auth failure
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
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  /// Fetch pending orders with pagination and search
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
      
      if (kDebugMode) {
        print('GET Request: $uri');
        print('Headers: ${_env.headers}');
      }
      
      final response = await http.get(uri, headers: _env.headers);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _validateOrderResponse(data);
        return data;
      } else if (response.statusCode == 401) {
        _env.clearAuthToken(); // Clear cached token on auth failure
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
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  /// Create a new order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders');
      
      if (kDebugMode) {
        print('POST Request: $uri');
        print('Headers: ${_env.headers}');
        print('Body: $orderData');
      }
      
      final response = await http.post(
        uri,
        headers: _env.headers,
        body: jsonEncode(orderData),
      );

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _env.clearAuthToken();
        throw Exception('Invalid API key or authentication failed');
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      rethrow;
    }
  }

  /// Update an existing order
  Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> orderData) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders');
      final data = {
        'id': id,
        ...orderData,
      };
      
      if (kDebugMode) {
        print('PUT Request: $uri');
        print('Headers: ${_env.headers}');
        print('Body: $data');
      }
      
      final response = await http.put(
        uri,
        headers: _env.headers,
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _env.clearAuthToken();
        throw Exception('Invalid API key or authentication failed');
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order: $e');
      }
      rethrow;
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String id) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders').replace(
        queryParameters: {'id': id},
      );
      
      if (kDebugMode) {
        print('DELETE Request: $uri');
        print('Headers: ${_env.headers}');
      }
      
      final response = await http.delete(uri, headers: _env.headers);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        _env.clearAuthToken();
        throw Exception('Invalid API key or authentication failed');
      } else {
        throw Exception('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting order: $e');
      }
      rethrow;
    }
  }

  /// Validate order response structure
  void _validateOrderResponse(Map<String, dynamic> data) {
    if (!data.containsKey('orders')) {
      throw Exception('Invalid response: missing orders array');
    }
    if (!data.containsKey('page')) {
      throw Exception('Invalid response: missing page number');
    }
    if (!data.containsKey('per_page')) {
      throw Exception('Invalid response: missing per_page value');
    }
    if (!data.containsKey('total')) {
      throw Exception('Invalid response: missing total count');
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