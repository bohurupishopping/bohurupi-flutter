import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../../components/common/orders_page_layout.dart';
import '../../models/firebase_order.dart';
import '../../providers/orders/firebase_orders_provider.dart';

// Cache time provider with a const duration
final completedOrdersCacheTimeProvider = StateProvider<DateTime?>((ref) => null);

@immutable
class FirebaseCompletedPage extends HookConsumerWidget {
  const FirebaseCompletedPage({super.key});

  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(completedOrdersNotifierProvider);
    final lastFetchTime = ref.watch(completedOrdersCacheTimeProvider);
    
    // Memoize cache validation function
    final isCacheValid = useCallback(() {
      if (lastFetchTime == null) return false;
      final now = DateTime.now();
      return now.difference(lastFetchTime) < _cacheDuration;
    }, [lastFetchTime]);

    // Debounced search function
    final searchDebouncer = useRef<Timer?>(null);

    // Load orders on first build using useEffect for better performance
    useEffect(() {
      if (state.orders.isEmpty || !isCacheValid()) {
        // Use microtask to avoid blocking the UI
        Future.microtask(() {
          ref.read(completedOrdersNotifierProvider.notifier).fetchOrders();
          ref.read(completedOrdersCacheTimeProvider.notifier).state = DateTime.now();
        });
      }
      return null;
    }, const []);

    // Memoize the orders list conversion to avoid unnecessary rebuilds
    final orders = useMemoized(
      () => state.orders.map((order) => FirebaseOrder.fromJson(order)).toList(),
      [state.orders],
    );

    // Memoize the refresh callback
    final onRefresh = useCallback(
      () async {
        await ref.read(completedOrdersNotifierProvider.notifier).fetchOrders();
        ref.read(completedOrdersCacheTimeProvider.notifier).state = DateTime.now();
      },
      const [],
    );

    // Memoize the search callback with debouncing
    final onSearch = useCallback(
      (String value) {
        searchDebouncer.value?.cancel();
        searchDebouncer.value = Timer(_debounceDelay, () {
          if (!isCacheValid()) {
            ref.read(completedOrdersNotifierProvider.notifier).fetchOrders();
            ref.read(completedOrdersCacheTimeProvider.notifier).state = DateTime.now();
          }
          ref.read(completedOrdersNotifierProvider.notifier).setSearchQuery(value);
        });
      },
      [isCacheValid],
    );

    // Memoize the page change callback
    final onPageChanged = useCallback(
      (int page) {
        if (!isCacheValid()) {
          ref.read(completedOrdersNotifierProvider.notifier).fetchOrders();
          ref.read(completedOrdersCacheTimeProvider.notifier).state = DateTime.now();
        }
        ref.read(completedOrdersNotifierProvider.notifier).setPage(page);
      },
      [isCacheValid],
    );

    // Cleanup debouncer on dispose
    useEffect(() {
      return () {
        searchDebouncer.value?.cancel();
      };
    }, const []);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.07),
            theme.colorScheme.tertiary.withOpacity(0.05),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: OrdersPageLayout(
          title: 'Completed Orders',
          icon: FontAwesomeIcons.boxArchive,
          orders: orders,
          isLoading: state.isLoading,
          error: state.error,
          onRefresh: onRefresh,
          onSearch: onSearch,
          onPageChanged: onPageChanged,
          currentPage: state.page,
          totalPages: state.totalPages,
        ),
      ),
    );
  }
} 