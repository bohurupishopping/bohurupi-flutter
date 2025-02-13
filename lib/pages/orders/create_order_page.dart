import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/orders/order_form.dart';
import '../../components/orders/order_table.dart';
import '../../components/floating_nav_bar.dart';
import '../../models/api_order.dart';
import '../../services/api_orders_service.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _searchController = TextEditingController();
  final _apiOrdersService = ApiOrdersService();
  
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isTableView = true;
  String? _error;
  Map<String, dynamic>? _orderDetails;
  List<ApiOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiOrdersService.getOrders(status: 'pending');
      setState(() {
        _orders = response.orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Mock function to simulate WooCommerce order search
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
      if (_orderDetails != null && _orderDetails!['id'] != null) {
        await _apiOrdersService.updateOrder(_orderDetails!['id'], data);
      } else {
        await _apiOrdersService.createOrder(data);
      }
      setState(() {
        _isTableView = true;
        _orderDetails = null;
      });
      await _fetchOrders();
    } catch (e) {
      // TODO: Show error message
      print('Error submitting order: $e');
    }
  }

  Future<void> _handleOrderDelete(String orderId) async {
    try {
      await _apiOrdersService.deleteOrder(orderId);
      await _fetchOrders();
    } catch (e) {
      // TODO: Show error message
      print('Error deleting order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(child: Text('Error: $_error'))
                              : _isTableView
                                  ? SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: OrderTable(
                                        orders: _orders,
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
                                          if (_orderDetails != null)
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