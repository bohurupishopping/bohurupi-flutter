import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../components/create_order/order_form.dart';
import '../../components/create_order/order_table.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../models/api_order.dart';
import '../../providers/orders/api_orders_provider.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isTableView = true;
  Map<String, dynamic>? _orderDetails;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchOrder() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: Implement actual WooCommerce order search
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _orderDetails = {
          'orderId': _searchController.text,
          'customerName': 'John Doe',
          'orderstatus': 'Prepaid',
          'status': 'pending',
          'products': [
            {
              'details': 'Test Product 1',
              'image': 'https://picsum.photos/200',
              'sku': 'TST001',
              'sale_price': 999,
              'product_page_url': 'https://example.com',
              'product_category': 'Category 1 | Category 2',
              'colour': 'Red',
              'size': 'XL',
              'qty': 1,
            },
          ],
        };
        _isTableView = false;
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _handleOrderSubmit(Map<String, dynamic> data) async {
    try {
      final mutations = ref.read(apiOrderMutationsProvider);
      if (_orderDetails != null && _orderDetails!['id'] != null) {
        await mutations.updateOrder(_orderDetails!['id'], data);
      } else {
        await mutations.createOrder(data);
      }
      setState(() {
        _isTableView = true;
        _orderDetails = null;
      });
      // Refresh orders list
      ref.invalidate(apiOrdersProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleOrderDelete(String orderId) async {
    try {
      final mutations = ref.read(apiOrderMutationsProvider);
      await mutations.deleteOrder(orderId);
      // Refresh orders list
      ref.invalidate(apiOrdersProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsyncValue = ref.watch(apiOrdersProvider(const ApiOrdersFilter()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.8),
                      theme.colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with search
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Row with View Toggle
                          Row(
                            children: [
                              // Title with custom container
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(0.1),
                                      theme.colorScheme.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isTableView ? Iconsax.task_square : FontAwesomeIcons.plus,
                                        size: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isTableView ? 'Orders' : 'Create Order',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // View Toggle Button
                              FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _isTableView = !_isTableView;
                                    if (_isTableView) {
                                      _orderDetails = null;
                                    }
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isTableView ? FontAwesomeIcons.plus : Iconsax.task_square,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isTableView ? 'Create New' : 'View Orders',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!_isTableView) ...[
                            const SizedBox(height: 12),
                            // Search WooCommerce order
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.colorScheme.outline.withOpacity(0.1),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onSubmitted: (_) => _searchOrder(),
                                      style: theme.textTheme.bodySmall,
                                      decoration: InputDecoration(
                                        hintText: 'Enter WooCommerce Order ID...',
                                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        prefixIcon: Icon(
                                          Iconsax.search_normal,
                                          size: 16,
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isSearching ? null : _searchOrder,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            if (_isSearching)
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            else
                                              const FaIcon(
                                                FontAwesomeIcons.magnifyingGlass,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isSearching ? 'Searching...' : 'Search',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: ordersAsyncValue.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading orders',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.tonal(
                                  onPressed: () => ref.invalidate(apiOrdersProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (response) => _isTableView
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: OrderTable(
                                orders: response.orders,
                                onEdit: (order) {
                                  setState(() {
                                    _orderDetails = order.toJson();
                                    _isTableView = false;
                                  });
                                },
                                onDelete: _handleOrderDelete,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OrderForm(
                                    initialData: _orderDetails,
                                    onSubmit: _handleOrderSubmit,
                                    onCancel: () {
                                      setState(() {
                                        _orderDetails = null;
                                        _isTableView = true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 