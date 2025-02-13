import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
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

/// Loading state provider
final apiOrdersLoadingProvider = StateProvider<bool>((ref) => false);

/// Error state provider
final apiOrdersErrorProvider = StateProvider<String?>((ref) => null);

/// Orders filter state provider
final apiOrdersFilterProvider = StateProvider<ApiOrdersFilter>((ref) {
  return const ApiOrdersFilter();
});

/// Orders response provider
final apiOrdersProvider = FutureProvider.family<ApiOrdersResponse, ApiOrdersFilter>((ref, filter) async {
  final service = ref.watch(apiOrdersServiceProvider);
  
  // Update loading state
  ref.read(apiOrdersLoadingProvider.notifier).state = true;
  // Clear previous error
  ref.read(apiOrdersErrorProvider.notifier).state = null;
  
  try {
    final response = await service.getOrders(
      status: filter.status,
      page: filter.page,
      perPage: filter.perPage,
      search: filter.search,
    );
    return response;
  } catch (e) {
    // Update error state
    ref.read(apiOrdersErrorProvider.notifier).state = e.toString();
    rethrow;
  } finally {
    // Reset loading state
    ref.read(apiOrdersLoadingProvider.notifier).state = false;
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
    ref.read(apiOrdersLoadingProvider.notifier).state = true;
    ref.read(apiOrdersErrorProvider.notifier).state = null;

    try {
      final order = await service.createOrder(orderData);
      // Invalidate the orders cache to trigger a refresh
      ref.invalidate(apiOrdersProvider);
      return order;
    } catch (e) {
      ref.read(apiOrdersErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      ref.read(apiOrdersLoadingProvider.notifier).state = false;
    }
  }

  /// Update an existing order
  Future<ApiOrder> updateOrder(String id, Map<String, dynamic> orderData) async {
    ref.read(apiOrdersLoadingProvider.notifier).state = true;
    ref.read(apiOrdersErrorProvider.notifier).state = null;

    try {
      final order = await service.updateOrder(id, orderData);
      // Invalidate the orders cache to trigger a refresh
      ref.invalidate(apiOrdersProvider);
      return order;
    } catch (e) {
      ref.read(apiOrdersErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      ref.read(apiOrdersLoadingProvider.notifier).state = false;
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String id) async {
    ref.read(apiOrdersLoadingProvider.notifier).state = true;
    ref.read(apiOrdersErrorProvider.notifier).state = null;

    try {
      await service.deleteOrder(id);
      // Invalidate the orders cache to trigger a refresh
      ref.invalidate(apiOrdersProvider);
    } catch (e) {
      ref.read(apiOrdersErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      ref.read(apiOrdersLoadingProvider.notifier).state = false;
    }
  }

  /// Change order status
  Future<ApiOrder> changeOrderStatus(String id, ApiOrderStatus status) async {
    return updateOrder(id, {'status': status.value});
  }
} 