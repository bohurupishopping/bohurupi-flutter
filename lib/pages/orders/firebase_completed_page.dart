import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/common/orders_page_layout.dart';
import '../../models/firebase_order.dart';
import '../../providers/orders/firebase_orders_provider.dart';

class FirebaseCompletedPage extends HookConsumerWidget {
  const FirebaseCompletedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedOrdersNotifierProvider);
    
    // Load orders on first build
    ref.listen(completedOrdersNotifierProvider, (previous, next) {
      if (previous == null) {
        ref.read(completedOrdersNotifierProvider.notifier).fetchOrders();
      }
    });

    return OrdersPageLayout(
      title: 'Completed Orders',
      icon: FontAwesomeIcons.boxArchive,
      orders: state.orders.map((order) => FirebaseOrder.fromJson(order)).toList(),
      isLoading: state.isLoading,
      error: state.error,
      onRefresh: () => ref.read(completedOrdersNotifierProvider.notifier).fetchOrders(),
      onSearch: (value) => ref.read(completedOrdersNotifierProvider.notifier).setSearchQuery(value),
      onPageChanged: (page) => ref.read(completedOrdersNotifierProvider.notifier).setPage(page),
      currentPage: state.page,
      totalPages: state.totalPages,
    );
  }
} 