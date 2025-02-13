import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/woo_order.dart';
import '../../services/woo_orders_service.dart';
import '../../services/environment_service.dart';

final wooOrdersServiceProvider = Provider((ref) {
  return WooOrdersService();
});

class WooOrdersState {
  final List<WooOrder> orders;
  final bool isLoading;
  final WooOrder? selectedOrder;
  final bool isDialogOpen;
  final String searchQuery;
  final String statusFilter;
  final int currentPage;
  final int totalPages;
  final String? error;
  final int perPage;

  const WooOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.selectedOrder,
    this.isDialogOpen = false,
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.currentPage = 1,
    this.totalPages = 1,
    this.error,
    this.perPage = 50,
  });

  WooOrdersState copyWith({
    List<WooOrder>? orders,
    bool? isLoading,
    WooOrder? selectedOrder,
    bool? isDialogOpen,
    String? searchQuery,
    String? statusFilter,
    int? currentPage,
    int? totalPages,
    String? error,
    int? perPage,
  }) {
    return WooOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      isDialogOpen: isDialogOpen ?? this.isDialogOpen,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: error,
      perPage: perPage ?? this.perPage,
    );
  }
}

class WooOrdersNotifier extends StateNotifier<WooOrdersState> {
  final WooOrdersService _service;

  WooOrdersNotifier(this._service) : super(const WooOrdersState());

  Future<void> fetchOrders() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _service.getOrders(
        page: state.currentPage,
        perPage: state.perPage,
        search: state.searchQuery,
        status: state.statusFilter == 'all' ? null : state.statusFilter,
      );

      final orders = (result['orders'] as List)
          .map((order) => WooOrder.fromJson(order))
          .toList();

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        totalPages: result['totalPages'] as int,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchOrderDetails(String orderId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final orderData = await _service.getOrderDetails(orderId);
      final order = WooOrder.fromJson(orderData);

      state = state.copyWith(
        selectedOrder: order,
        isLoading: false,
        isDialogOpen: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
    );
    fetchOrders();
  }

  void setStatusFilter(String status) {
    state = state.copyWith(
      statusFilter: status,
      currentPage: 1,
    );
    fetchOrders();
  }

  void setPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    state = state.copyWith(currentPage: page);
    fetchOrders();
  }

  void selectOrder(Map<String, dynamic> order) {
    final wooOrder = WooOrder.fromJson(order);
    state = state.copyWith(
      selectedOrder: wooOrder,
      isDialogOpen: true,
    );
  }

  void closeDialog() {
    state = state.copyWith(
      selectedOrder: null,
      isDialogOpen: false,
    );
  }

  void setPerPage(int perPage) {
    state = state.copyWith(
      perPage: perPage,
      currentPage: 1, // Reset to first page when changing items per page
    );
    fetchOrders();
  }
}

final wooOrdersProvider = StateNotifierProvider<WooOrdersNotifier, WooOrdersState>((ref) {
  final service = ref.watch(wooOrdersServiceProvider);
  return WooOrdersNotifier(service);
}); 