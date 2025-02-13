import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/api_order.dart';
import 'environment_service.dart';

class ApiOrdersService {
  final EnvironmentService _env = EnvironmentService.instance;
  final String _endpoint = '/firebase/orders';

  String get _apiBaseUrl => '${_env.baseUrl}$_endpoint';

  Future<ApiOrdersResponse> getOrders({
    String? status,
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(_apiBaseUrl).replace(queryParameters: queryParams);
      
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
        return ApiOrdersResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<ApiOrder> createOrder(Map<String, dynamic> orderData) async {
    try {
      if (kDebugMode) {
        print('POST Request: $_apiBaseUrl');
        print('Headers: ${_env.headers}');
        print('Body: $orderData');
      }

      final response = await http.post(
        Uri.parse(_apiBaseUrl),
        headers: _env.headers,
        body: json.encode(orderData),
      );

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return ApiOrder.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      throw Exception('Failed to create order: $e');
    }
  }

  Future<ApiOrder> updateOrder(String id, Map<String, dynamic> orderData) async {
    try {
      if (kDebugMode) {
        print('PUT Request: $_apiBaseUrl');
        print('Headers: ${_env.headers}');
        print('Body: $orderData');
      }

      final response = await http.put(
        Uri.parse(_apiBaseUrl),
        headers: _env.headers,
        body: json.encode({
          'id': id,
          ...orderData,
        }),
      );

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return ApiOrder.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order: $e');
      }
      throw Exception('Failed to update order: $e');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      if (kDebugMode) {
        print('DELETE Request: $_apiBaseUrl?id=$id');
        print('Headers: ${_env.headers}');
      }

      final response = await http.delete(
        Uri.parse(_apiBaseUrl).replace(queryParameters: {'id': id}),
        headers: _env.headers,
      );

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting order: $e');
      }
      throw Exception('Failed to delete order: $e');
    }
  }
}

// Order Status Types
enum ApiOrderStatus {
  pending,
  completed;

  String get value {
    switch (this) {
      case ApiOrderStatus.pending:
        return 'pending';
      case ApiOrderStatus.completed:
        return 'completed';
    }
  }

  static ApiOrderStatus? fromString(String? status) {
    if (status == null) return null;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return ApiOrderStatus.pending;
      case 'completed':
        return ApiOrderStatus.completed;
      default:
        return null;
    }
  }
} 