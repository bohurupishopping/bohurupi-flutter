import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/woocommerce_service.dart';
import '../../models/api_order.dart';

/// WooCommerce Service provider
final wooCommerceServiceProvider = Provider<WooCommerceService>((ref) {
  return WooCommerceService();
});

/// Cache duration for WooCommerce responses
const _cacheDuration = Duration(minutes: 5);

/// Cache for WooCommerce order details
final wooOrderCacheProvider = StateProvider<Map<String, _CachedResponse>>((ref) => {});

/// Cache for WooCommerce product details
final wooProductCacheProvider = StateProvider<Map<String, _CachedResponse>>((ref) => {});

/// WooCommerce order details provider
final wooOrderProvider = FutureProvider.family<ApiOrder, String>((ref, orderId) async {
  final service = ref.watch(wooCommerceServiceProvider);
  final cache = ref.watch(wooOrderCacheProvider);
  
  // Check cache
  final cachedResponse = cache[orderId];
  if (cachedResponse != null && !cachedResponse.isExpired) {
    return service.transformWooOrder(cachedResponse.data);
  }
  
  // Fetch fresh data
  final orderData = await service.getOrderDetails(orderId);
  
  // Update cache
  ref.read(wooOrderCacheProvider.notifier).update((state) => {
    ...state,
    orderId: _CachedResponse(
      data: orderData,
      timestamp: DateTime.now(),
    ),
  });
  
  return service.transformWooOrder(orderData);
});

/// WooCommerce product details provider
final wooProductProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final service = ref.watch(wooCommerceServiceProvider);
  final cache = ref.watch(wooProductCacheProvider);
  
  // Check cache
  final cachedResponse = cache[productId];
  if (cachedResponse != null && !cachedResponse.isExpired) {
    return cachedResponse.data;
  }
  
  // Fetch fresh data
  final productData = await service.getProductDetails(productId);
  
  // Update cache
  ref.read(wooProductCacheProvider.notifier).update((state) => {
    ...state,
    productId: _CachedResponse(
      data: productData,
      timestamp: DateTime.now(),
    ),
  });
  
  return productData;
});

/// Cache response class
class _CachedResponse {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CachedResponse({
    required this.data,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > _cacheDuration;
} 