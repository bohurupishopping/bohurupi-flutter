import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/api_order.dart';
import '../../services/api_orders_service.dart';
import '../../services/environment_service.dart';

/// Environment configuration provider
final apiEnvironmentProvider = Provider<bool>((ref) {
  return EnvironmentService.instance.isDevelopment;
});

/// API Orders Service provider
final apiOrdersServiceProvider = Provider<ApiOrdersService>((ref) {
  return ApiOrdersService();
});

/// Orders filter state provider
final apiOrdersFilterProvider = StateProvider<ApiOrdersFilter>((ref) {
  return const ApiOrdersFilter();
});

/// Orders response provider
final apiOrdersProvider = FutureProvider.family<ApiOrdersResponse, ApiOrdersFilter>((ref, filter) async {
  final service = ref.watch(apiOrdersServiceProvider);
  
  try {
    final response = await service.getOrders(
      status: filter.status,
      page: filter.page,
      perPage: filter.perPage,
      search: filter.search,
    );
    return response;
  } catch (e) {
    throw e.toString();
  }
});

/// Orders mutation provider
final apiOrderMutationsProvider = Provider<ApiOrderMutations>((ref) {
  final service = ref.watch(apiOrdersServiceProvider);
  return ApiOrderMutations(
    service: service,
    ref: ref,
  );
});

/// Filter class for API orders
class ApiOrdersFilter {
  final String? status;
  final int page;
  final int perPage;
  final String? search;

  const ApiOrdersFilter({
    this.status,
    this.page = 1,
    this.perPage = 50,
    this.search,
  });

  ApiOrdersFilter copyWith({
    String? status,
    int? page,
    int? perPage,
    String? search,
  }) {
    return ApiOrdersFilter(
      status: status ?? this.status,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiOrdersFilter &&
        other.status == status &&
        other.page == page &&
        other.perPage == perPage &&
        other.search == search;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      page,
      perPage,
      search,
    );
  }
}

/// Mutations class for API orders
class ApiOrderMutations {
  final ApiOrdersService service;
  final Ref ref;

  ApiOrderMutations({
    required this.service,
    required this.ref,
  });

  /// Create a new order
  Future<ApiOrder> createOrder(Map<String, dynamic> orderData) async {
    try {
      final order = await service.createOrder(orderData);
      return order;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Update an existing order
  Future<ApiOrder> updateOrder(String id, Map<String, dynamic> orderData) async {
    try {
      final order = await service.updateOrder(id, orderData);
      return order;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String id) async {
    try {
      await service.deleteOrder(id);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Change order status
  Future<ApiOrder> changeOrderStatus(String id, ApiOrderStatus status) async {
    return updateOrder(id, {'status': status.value});
  }
} 