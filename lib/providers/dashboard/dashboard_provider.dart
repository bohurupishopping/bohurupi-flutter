import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/firebase_orders_service.dart';
import '../orders/firebase_orders_provider.dart';

// Cache duration for dashboard data
const _cacheDuration = Duration(minutes: 5);

class DashboardState {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const DashboardState({
    this.stats = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  bool get isCacheValid {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!) < _cacheDuration;
  }

  DashboardState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final FirebaseOrdersService _firebaseService;
  
  DashboardNotifier({
    required FirebaseOrdersService firebaseService,
  })  : _firebaseService = firebaseService,
        super(const DashboardState());

  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    try {
      // Return cached data if valid and not forcing refresh
      if (!forceRefresh && state.isCacheValid) {
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      final stats = await _fetchStats();

      state = state.copyWith(
        stats: stats,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    // Fetch completed and pending orders with full data to calculate total sales
    final completed = await _firebaseService.getCompletedOrders(perPage: 100);
    final pending = await _firebaseService.getPendingOrders(perPage: 100);
    
    final completedOrders = completed['orders'] as List? ?? [];
    final pendingOrders = pending['orders'] as List? ?? [];
    
    // Calculate total sales price
    double totalSales = 0;
    for (final order in [...completedOrders, ...pendingOrders]) {
      final products = order['products'] as List? ?? [];
      for (final product in products) {
        totalSales += (product['salePrice'] as num? ?? 0) * (product['qty'] as num? ?? 1);
      }
    }

    return {
      'totalOrders': completedOrders.length + pendingOrders.length,
      'pendingOrders': pendingOrders.length,
      'completedOrders': completedOrders.length,
      'totalSales': totalSales,
    };
  }

  // Method to force refresh the dashboard data
  Future<void> refresh() => loadDashboardData(forceRefresh: true);
}

// Cache provider for dashboard data
final dashboardCacheProvider = StateProvider<DashboardState?>((ref) => null);

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final firebaseService = ref.watch(firebaseOrdersServiceProvider);
  
  final notifier = DashboardNotifier(
    firebaseService: firebaseService,
  );
  
  // Watch the cache provider
  final cachedState = ref.watch(dashboardCacheProvider);
  
  // Initialize with cached state if available
  if (cachedState != null && cachedState.isCacheValid) {
    notifier.state = cachedState;
  }
  
  return notifier;
}); 