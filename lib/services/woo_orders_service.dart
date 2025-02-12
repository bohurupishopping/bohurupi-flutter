import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WooOrdersService {
  static const String apiKey = 'x84kjjfkdjk';
  
  // API URLs
  static const String _devBaseUrl = 'http://localhost:3000/api/woocommerce';
  static const String _prodBaseUrl = 'https://order.bohurupi.com/api/woocommerce';

  final bool isDev;

  WooOrdersService({
    bool? isDev,
  }) : isDev = isDev ?? kDebugMode {
    // Debug log
  }

  String get _apiBaseUrl => isDev ? _devBaseUrl : _prodBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  // Fetch orders list with pagination, search, and filters
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int perPage = 50,
    String? search,
    String? status,
    String orderBy = 'date',
    String order = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'orderby': orderBy,
        'order': order,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'all') 'status': status,
      };

      final uri = Uri.parse('$_apiBaseUrl/orders').replace(queryParameters: queryParams);
      
      // Debug log
      
      final response = await http.get(uri, headers: _headers);

      // Debug log
      // Debug log

      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body);
        final totalPages = int.tryParse(response.headers['x-wp-totalpages'] ?? '1') ?? 1;
        final total = int.tryParse(response.headers['x-wp-total'] ?? '0') ?? 0;

        return {
          'orders': orders,
          'total': total,
          'totalPages': totalPages,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      // Debug log
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Fetch single order details with notes
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders/$orderId');
      
      // Debug log
      
      final response = await http.get(uri, headers: _headers);

      // Debug log
      // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else {
        throw Exception('Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      // Debug log
      throw Exception('Failed to fetch order details: $e');
    }
  }
}

// Order Status Types
enum WooOrderStatus {
  pending,
  processing,
  onHold,
  completed,
  cancelled,
  refunded,
  failed,
  trash;

  String get value {
    switch (this) {
      case WooOrderStatus.pending:
        return 'pending';
      case WooOrderStatus.processing:
        return 'processing';
      case WooOrderStatus.onHold:
        return 'on-hold';
      case WooOrderStatus.completed:
        return 'completed';
      case WooOrderStatus.cancelled:
        return 'cancelled';
      case WooOrderStatus.refunded:
        return 'refunded';
      case WooOrderStatus.failed:
        return 'failed';
      case WooOrderStatus.trash:
        return 'trash';
    }
  }

  static WooOrderStatus? fromString(String? status) {
    if (status == null) return null;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return WooOrderStatus.pending;
      case 'processing':
        return WooOrderStatus.processing;
      case 'on-hold':
        return WooOrderStatus.onHold;
      case 'completed':
        return WooOrderStatus.completed;
      case 'cancelled':
        return WooOrderStatus.cancelled;
      case 'refunded':
        return WooOrderStatus.refunded;
      case 'failed':
        return WooOrderStatus.failed;
      case 'trash':
        return WooOrderStatus.trash;
      default:
        return null;
    }
  }
} 