import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/orders/woocommerce_provider.dart';
import '../../models/api_order.dart';
import 'product_card.dart';

class OrderForm extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>(), const []);
    final mounted = useIsMounted();
    
    // Form controllers
    final orderIdController = useTextEditingController(text: initialData?['orderId']?.toString() ?? '');
    final customerNameController = useTextEditingController(text: initialData?['customerName']?.toString() ?? '');
    final trackingIdController = useTextEditingController(text: initialData?['trackingId']?.toString() ?? '');
    final designUrlController = useTextEditingController(text: initialData?['designUrl']?.toString() ?? '');
    final searchController = useTextEditingController();
    
    // Form state
    final isLoading = useState(false);
    final orderStatus = useState(initialData?['orderstatus']?.toString() ?? 'Prepaid');
    final status = useState(initialData?['status']?.toString() ?? 'pending');
    final products = useState<List<Map<String, dynamic>>>(
      List<Map<String, dynamic>>.from(initialData?['products'] as List<dynamic>? ?? [])
    );
    final recentOrders = useState<List<String>>([]);
    final isSearchingOrder = useState(false);

    // Effects
    useEffect(() {
      // Fetch recent orders on mount
      if (mounted()) {
        _fetchRecentOrders(recentOrders);
      }
      return null;
    }, const []);

    // Search WooCommerce order
    Future<void> handleOrderSearch() async {
      final orderId = searchController.text;
      if (orderId.isEmpty) return;

      isSearchingOrder.value = true;
      try {
        final orderData = await ref.read(wooOrderProvider(orderId).future);
        
        // Only update state if widget is still mounted
        if (mounted()) {
          // Update form with order data
          orderIdController.text = orderData.orderId;
          customerNameController.text = orderData.customerName;
          orderStatus.value = orderData.orderstatus;
          status.value = orderData.status;
          products.value = orderData.products.map((p) => p.toJson()).toList();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${orderData.products.length} products in this order'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted()) {
          isSearchingOrder.value = false;
        }
      }
    }

    // Handle form submission
    Future<void> handleSubmit() async {
      if (formKey.currentState?.validate() ?? false) {
        isLoading.value = true;
        try {
          final formData = {
            'orderId': orderIdController.text,
            'customerName': customerNameController.text,
            'trackingId': trackingIdController.text,
            'designUrl': designUrlController.text,
            'orderstatus': orderStatus.value,
            'status': status.value,
            'products': products.value,
          };
          await onSubmit(formData);
        } finally {
          if (mounted()) {
            isLoading.value = false;
          }
        }
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEditing) ...[
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
                            controller: searchController,
                            decoration: const InputDecoration(
                              labelText: 'WooCommerce Order ID',
                              prefixIcon: Icon(Iconsax.search_normal),
                            ),
                            onFieldSubmitted: (_) => handleOrderSearch(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: isSearchingOrder.value ? null : handleOrderSearch,
                          icon: isSearchingOrder.value 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Iconsax.search_normal),
                          label: Text(isSearchingOrder.value ? 'Searching...' : 'Search'),
                        ),
                      ],
                    ),
                    if (recentOrders.value.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recent Orders:',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentOrders.value.map((orderId) => ActionChip(
                          label: Text('#$orderId'),
                          onPressed: () {
                            searchController.text = orderId;
                            handleOrderSearch();
                          },
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
                          controller: orderIdController,
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
                          controller: customerNameController,
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
                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: orderStatus.value,
                              decoration: const InputDecoration(
                                labelText: 'Payment Status',
                                prefixIcon: Icon(Iconsax.money),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Prepaid', child: Text('Prepaid')),
                                DropdownMenuItem(value: 'COD', child: Text('COD')),
                              ],
                              onChanged: (value) {
                                if (value != null && mounted()) {
                                  orderStatus.value = value;
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: status.value,
                              decoration: const InputDecoration(
                                labelText: 'Order Status',
                                prefixIcon: Icon(Iconsax.status),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              ],
                              onChanged: (value) {
                                if (value != null && mounted()) {
                                  status.value = value;
                                }
                              },
                            ),
                          ],
                        );
                      }
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: orderStatus.value,
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
                                  if (value != null && mounted()) {
                                    orderStatus.value = value;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: status.value,
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
                                  if (value != null && mounted()) {
                                    status.value = value;
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
                    controller: designUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Design URL',
                      prefixIcon: Icon(Iconsax.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: trackingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking/AWB Number',
                      prefixIcon: Icon(Iconsax.truck),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (products.value.isNotEmpty) ...[
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
                          '${products.value.length} items',
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
                      itemCount: products.value.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => ProductCard(
                        product: products.value[index],
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
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: isLoading.value ? null : handleSubmit,
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEditing ? 'Update Order' : 'Create Order'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _fetchRecentOrders(ValueNotifier<List<String>> recentOrders) async {
  // TODO: Implement fetching recent orders from WooCommerce
  recentOrders.value = ['12345', '12346', '12347', '12348', '12349'];
} 