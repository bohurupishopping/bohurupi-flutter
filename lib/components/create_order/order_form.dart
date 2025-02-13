import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'product_card.dart';

class OrderForm extends ConsumerStatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> data) onSubmit;
  final VoidCallback onCancel;

  const OrderForm({
    super.key,
    this.isEditing = false,
    this.initialData,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  ConsumerState<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends ConsumerState<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late final TextEditingController _orderIdController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _trackingIdController;
  late final TextEditingController _designUrlController;
  late final TextEditingController _searchController;
  
  String _orderStatus = 'Prepaid';
  String _status = 'pending';
  List<Map<String, dynamic>> _products = [];
  List<String> _recentOrders = [];
  bool _isSearchingOrder = false;

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(text: widget.initialData?['orderId']?.toString() ?? '');
    _customerNameController = TextEditingController(text: widget.initialData?['customerName']?.toString() ?? '');
    _trackingIdController = TextEditingController(text: widget.initialData?['trackingId']?.toString() ?? '');
    _designUrlController = TextEditingController(text: widget.initialData?['designUrl']?.toString() ?? '');
    _searchController = TextEditingController();
    _orderStatus = widget.initialData?['orderstatus']?.toString() ?? 'Prepaid';
    _status = widget.initialData?['status']?.toString() ?? 'pending';
    _products = List<Map<String, dynamic>>.from(widget.initialData?['products'] as List<dynamic>? ?? []);
    _fetchRecentOrders();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerNameController.dispose();
    _trackingIdController.dispose();
    _designUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecentOrders() async {
    // TODO: Implement fetching recent orders from WooCommerce
    setState(() {
      _recentOrders = ['12345', '12346', '12347', '12348', '12349'];
    });
  }

  Future<void> _searchOrder(String orderId) async {
    if (orderId.isEmpty) return;

    setState(() {
      _isSearchingOrder = true;
    });

    try {
      // TODO: Implement actual WooCommerce order search
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response
      final orderData = {
        'orderId': orderId,
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

      setState(() {
        _orderIdController.text = orderData['orderId']?.toString() ?? '';
        _customerNameController.text = orderData['customerName']?.toString() ?? '';
        _orderStatus = orderData['orderstatus']?.toString() ?? 'Prepaid';
        _status = orderData['status']?.toString() ?? 'pending';
        _products = List<Map<String, dynamic>>.from(orderData['products'] as List<dynamic>? ?? []);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${_products.length} products in this order'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingOrder = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final formData = {
          'orderId': _orderIdController.text,
          'customerName': _customerNameController.text,
          'trackingId': _trackingIdController.text,
          'designUrl': _designUrlController.text,
          'orderstatus': _orderStatus,
          'status': _status,
          'products': _products,
        };
        await widget.onSubmit(formData);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isEditing) ...[
            // Search Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search WooCommerce Order',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'WooCommerce Order ID',
                              prefixIcon: Icon(Iconsax.search_normal),
                            ),
                            onFieldSubmitted: _searchOrder,
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: _isSearchingOrder ? null : () => _searchOrder(_searchController.text),
                          icon: _isSearchingOrder 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Iconsax.search_normal),
                          label: Text(_isSearchingOrder ? 'Searching...' : 'Search'),
                        ),
                      ],
                    ),
                    if (_recentOrders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recent Orders:',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recentOrders.map((orderId) => ActionChip(
                          label: Text('#$orderId'),
                          onPressed: () => _searchOrder(orderId),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Basic Order Details Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _orderIdController,
                          decoration: const InputDecoration(
                            labelText: 'Order ID',
                            prefixIcon: Icon(Iconsax.document),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Order ID is required';
                            }
                            return null;
                          },
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name',
                            prefixIcon: Icon(Iconsax.user),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Customer name is required';
                            }
                            return null;
                          },
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on smaller screens
                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _orderStatus,
                              decoration: const InputDecoration(
                                labelText: 'Payment Status',
                                prefixIcon: Icon(Iconsax.money),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Prepaid', child: Text('Prepaid')),
                                DropdownMenuItem(value: 'COD', child: Text('COD')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _orderStatus = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Order Status',
                                prefixIcon: Icon(Iconsax.status),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                            ),
                          ],
                        );
                      }
                      // Side by side on larger screens
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _orderStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Payment Status',
                                  prefixIcon: Icon(Iconsax.money),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Prepaid', child: Text('Prepaid')),
                                  DropdownMenuItem(value: 'COD', child: Text('COD')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _orderStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Order Status',
                                  prefixIcon: Icon(Iconsax.status),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _status = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional Details Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _designUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Design URL',
                      prefixIcon: Icon(Iconsax.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _trackingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking/AWB Number',
                      prefixIcon: Icon(Iconsax.truck),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_products.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Products',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_products.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => ProductCard(
                        product: _products[index],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.isEditing ? 'Update Order' : 'Create Order'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 