import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/common/orders_page_layout.dart';
import '../../models/firebase_order.dart';
import '../../providers/orders/firebase_orders_provider.dart';

// Cache time provider
final pendingOrdersCacheTimeProvider = StateProvider<DateTime?>((ref) => null);

class FirebasePendingPage extends HookConsumerWidget {
  const FirebasePendingPage({super.key});

  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingOrdersNotifierProvider);
    final lastFetchTime = ref.watch(pendingOrdersCacheTimeProvider);
    
    // Check if cache is valid
    bool isCacheValid() {
      if (lastFetchTime == null) return false;
      final now = DateTime.now();
      return now.difference(lastFetchTime) < _cacheDuration;
    }

    // Load orders on first build using useEffect for better performance
    useEffect(() {
      // Only fetch if we don't have data or cache is invalid
      if (state.orders.isEmpty || !isCacheValid()) {
        // Use microtask to avoid blocking the UI
        Future.microtask(() {
          ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders();
          ref.read(pendingOrdersCacheTimeProvider.notifier).state = DateTime.now();
        });
      }
      return null;
    }, const []);

    // Memoize the orders list conversion to avoid unnecessary rebuilds
    final orders = useMemoized(
      () => state.orders.map((order) => FirebaseOrder.fromJson(order)).toList(),
      [state.orders],
    );

    // Memoize callbacks to prevent unnecessary rebuilds
    final onRefresh = useCallback(
      () async {
        await ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders();
        ref.read(pendingOrdersCacheTimeProvider.notifier).state = DateTime.now();
      },
      const [],
    );

    final onSearch = useCallback(
      (String value) {
        // If the cache is invalid, fetch fresh data before searching
        if (!isCacheValid()) {
          ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders();
          ref.read(pendingOrdersCacheTimeProvider.notifier).state = DateTime.now();
        }
        ref.read(pendingOrdersNotifierProvider.notifier).setSearchQuery(value);
      },
      const [],
    );

    final onPageChanged = useCallback(
      (int page) {
        // If the cache is invalid, fetch fresh data before changing page
        if (!isCacheValid()) {
          ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders();
          ref.read(pendingOrdersCacheTimeProvider.notifier).state = DateTime.now();
        }
        ref.read(pendingOrdersNotifierProvider.notifier).setPage(page);
      },
      const [],
    );

    return OrdersPageLayout(
      title: 'Pending Orders',
      icon: FontAwesomeIcons.clockRotateLeft,
      orders: orders,
      isLoading: state.isLoading,
      error: state.error,
      onRefresh: onRefresh,
      onSearch: onSearch,
      onPageChanged: onPageChanged,
      currentPage: state.page,
      totalPages: state.totalPages,
    );
  }
} 