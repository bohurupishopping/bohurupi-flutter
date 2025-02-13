import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/firebase_orders_service.dart';
import '../../services/environment_service.dart';

// Provider for the FirebaseOrdersService instance
final firebaseOrdersServiceProvider = Provider<FirebaseOrdersService>((ref) {
  return FirebaseOrdersService();
});

// State class for orders
class OrdersState {
  final List<dynamic> orders;
  final bool isLoading;
  final String? error;
  final int page;
  final int perPage;
  final String? searchQuery;
  final int totalPages;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.perPage = 50,
    this.searchQuery,
    this.totalPages = 1,
  });

  OrdersState copyWith({
    List<dynamic>? orders,
    bool? isLoading,
    String? error,
    int? page,
    int? perPage,
    String? searchQuery,
    int? totalPages,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Notifier for completed orders
class CompletedOrdersNotifier extends StateNotifier<OrdersState> {
  final FirebaseOrdersService _service;
  
  CompletedOrdersNotifier(this._service) : super(OrdersState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _service.getCompletedOrders(
        page: state.page,
        perPage: state.perPage,
        search: state.searchQuery,
      );

      state = state.copyWith(
        orders: result['orders'] as List,
        isLoading: false,
        totalPages: ((result['total'] as int) / state.perPage).ceil(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    fetchOrders();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, page: 1);
    fetchOrders();
  }
}

// Notifier for pending orders
class PendingOrdersNotifier extends StateNotifier<OrdersState> {
  final FirebaseOrdersService _service;
  
  PendingOrdersNotifier(this._service) : super(OrdersState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _service.getPendingOrders(
        page: state.page,
        perPage: state.perPage,
        search: state.searchQuery,
      );

      state = state.copyWith(
        orders: result['orders'] as List,
        isLoading: false,
        totalPages: ((result['total'] as int) / state.perPage).ceil(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    fetchOrders();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, page: 1);
    fetchOrders();
  }
}

// Providers
final completedOrdersNotifierProvider = StateNotifierProvider<CompletedOrdersNotifier, OrdersState>((ref) {
  final service = ref.watch(firebaseOrdersServiceProvider);
  return CompletedOrdersNotifier(service);
});

final pendingOrdersNotifierProvider = StateNotifierProvider<PendingOrdersNotifier, OrdersState>((ref) {
  final service = ref.watch(firebaseOrdersServiceProvider);
  return PendingOrdersNotifier(service);
}); 