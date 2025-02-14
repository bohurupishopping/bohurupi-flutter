import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/api_order.dart';
import 'environment_service.dart';

/// Service for interacting with WooCommerce API
class WooCommerceService {
  final EnvironmentService _env = EnvironmentService.instance;
  final String _endpoint = '/woocommerce';

  String get _apiBaseUrl => '${_env.baseUrl}$_endpoint';

  /// Fetch order details from WooCommerce
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders/$orderId');
      
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
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else {
        throw Exception('Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order details: $e');
      }
      rethrow;
    }
  }

  /// Fetch product details from WooCommerce
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/products/$productId');
      
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
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key or authentication failed');
      } else {
        throw Exception('Failed to fetch product details: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product details: $e');
      }
      rethrow;
    }
  }

  /// Transform WooCommerce order to Firebase order format
  ApiOrder transformWooOrder(Map<String, dynamic> wooOrder) {
    final lineItems = wooOrder['line_items'] as List<dynamic>;
    final billing = wooOrder['billing'] as Map<String, dynamic>;

    return ApiOrder(
      orderId: wooOrder['number'],
      status: 'pending',
      orderstatus: wooOrder['payment_method'] == 'cod' ? 'COD' : 'Prepaid',
      customerName: '${billing['first_name']} ${billing['last_name']}',
      email: billing['email'],
      phone: billing['phone'],
      address: _formatAddress(billing),
      products: lineItems.map((item) {
        // Extract meta data for color and size
        final metaData = item['meta_data'] as List<dynamic>;
        String? color;
        String? size;
        
        for (final meta in metaData) {
          if (meta['key'] == 'select_colour') {
            color = meta['value'];
          } else if (meta['key'] == 'select_size') {
            size = meta['value'];
          }
        }

        // Extract image URL from the image object
        final image = item['image'] as Map<String, dynamic>?;
        final imageUrl = image?['src'] ?? '';

        return ApiOrderProduct(
          details: item['name'],
          image: imageUrl,
          orderName: item['name'],
          sku: item['sku'] ?? '',
          salePrice: double.parse(item['price']?.toString() ?? '0'),
          productPageUrl: '', // We'll get this from product details if needed
          productCategory: '', // We'll get this from product details if needed
          colour: color ?? '',
          size: size ?? '',
          qty: item['quantity'],
        );
      }).toList(),
    );
  }

  /// Format billing address
  String _formatAddress(Map<String, dynamic> billing) {
    final parts = [
      billing['address_1'],
      billing['address_2'],
      billing['city'],
      billing['state'],
      billing['postcode'],
      billing['country'],
    ].where((part) => part != null && part.toString().isNotEmpty);
    
    return parts.join(', ');
  }

  /// Extract meta value from WooCommerce meta data
  String? _extractMetaValue(List<dynamic> metaData, String key) {
    final meta = metaData.firstWhere(
      (item) => item['key'] == key,
      orElse: () => null,
    );
    return meta?['value'];
  }
} 