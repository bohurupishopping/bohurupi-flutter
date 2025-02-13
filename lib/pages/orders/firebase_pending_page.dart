import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/common/orders_page_layout.dart';
import '../../models/firebase_order.dart';
import '../../providers/orders/firebase_orders_provider.dart';

class FirebasePendingPage extends HookConsumerWidget {
  const FirebasePendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingOrdersNotifierProvider);
    
    // Load orders on first build
    ref.listen(pendingOrdersNotifierProvider, (previous, next) {
      if (previous == null) {
        ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders();
      }
    });

    return OrdersPageLayout(
      title: 'Pending Orders',
      icon: FontAwesomeIcons.clockRotateLeft,
      orders: state.orders.map((order) => FirebaseOrder.fromJson(order)).toList(),
      isLoading: state.isLoading,
      error: state.error,
      onRefresh: () => ref.read(pendingOrdersNotifierProvider.notifier).fetchOrders(),
      onSearch: (value) => ref.read(pendingOrdersNotifierProvider.notifier).setSearchQuery(value),
      onPageChanged: (page) => ref.read(pendingOrdersNotifierProvider.notifier).setPage(page),
      currentPage: state.page,
      totalPages: state.totalPages,
    );
  }
} 