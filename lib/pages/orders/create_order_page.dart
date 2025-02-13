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

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> with AutomaticKeepAliveClientMixin {
  bool _isTableView = true;
  Map<String, dynamic>? _orderDetails;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load orders on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(apiOrdersProvider(const ApiOrdersFilter()));
    });
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(apiOrdersProvider(const ApiOrdersFilter()));
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
      _refreshKey.currentState?.show();
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
      _refreshKey.currentState?.show();
      
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
    super.build(context);
    final theme = Theme.of(context);
    final ordersAsyncValue = ref.watch(apiOrdersProvider(const ApiOrdersFilter()));
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
                margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
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
                    // Header
                    _buildHeader(theme, isSmallScreen),

                    // Content
                    Expanded(
                      child: ordersAsyncValue.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => _buildErrorView(theme, error),
                        data: (response) => _isTableView
                          ? RefreshIndicator(
                              key: _refreshKey,
                              onRefresh: _handleRefresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
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
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
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

  Widget _buildHeader(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 8 : 12,
      ),
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
          // Title Row with View Toggle and Refresh Button
          Row(
            children: [
              // Title with custom container
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
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
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTableView ? Iconsax.task_square : FontAwesomeIcons.plus,
                        size: isSmallScreen ? 10 : 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      _isTableView ? 'Orders' : 'Create Order',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Refresh Button
              if (_isTableView) ...[
                _buildRefreshButton(theme, isSmallScreen),
                SizedBox(width: isSmallScreen ? 6 : 8),
              ],
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTableView ? FontAwesomeIcons.plus : Iconsax.task_square,
                      size: isSmallScreen ? 10 : 12,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      _isTableView ? 'Create New' : 'View Orders',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme, bool isSmallScreen) {
    return FilledButton.tonal(
      onPressed: _handleRefresh,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.refresh,
            size: isSmallScreen ? 10 : 12,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            'Refresh',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, Object error) {
    return Center(
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
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
} 