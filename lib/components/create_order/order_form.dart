import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/orders/woocommerce_provider.dart';
import 'product_card.dart';

class OrderForm extends HookConsumerWidget {
  static const double _kSpacing = 16.0;
  static const double _kSmallSpacing = 12.0;
  static const double _kCardPadding = 16.0;
  static const double _kBorderRadius = 12.0;
  static const double _kIconSize = 16.0;
  static const double _kSmallIconSize = 14.0;
  
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
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final formPadding = mediaQuery.padding + const EdgeInsets.all(_kSpacing);
    
    // Form state using hooks with proper cleanup
    final formKey = useMemoized(() => GlobalKey<FormState>(), const []);
    final mounted = useIsMounted();
    
    // Memoized controllers with cleanup
    final controllers = useMemoized(() => _createControllers(initialData), [initialData]);
    useEffect(() => () => _disposeControllers(controllers), [controllers]);

    // Form state using hooks
    final isLoading = useState(false);
    final orderStatus = useState(initialData?['orderstatus']?.toString() ?? 'Prepaid');
    final status = useState(initialData?['status']?.toString() ?? 'pending');
    final products = useState<List<Map<String, dynamic>>>(
      List<Map<String, dynamic>>.from(initialData?['products'] as List<dynamic>? ?? [])
    );
    final recentOrders = useState<List<String>>([]);
    final isSearchingOrder = useState(false);

    // Fetch recent orders on mount
    useEffect(() {
      if (mounted()) {
        _fetchRecentOrders(recentOrders);
      }
      return null;
    }, const []);

    // Memoized handlers
    final handleOrderSearch = useCallback(_createOrderSearchHandler(
      ref, mounted, controllers, orderStatus, status, products, context, theme
    ), [controllers, mounted]);

    final handleSubmit = useCallback(_createSubmitHandler(
      formKey, isLoading, controllers, orderStatus, status, products, onSubmit, mounted
    ), [formKey, controllers, orderStatus.value, status.value, products.value, onSubmit, mounted]);

    return Dialog(
      insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? mediaQuery.size.width : 800,
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
          child: Column(
            children: [
              // Enhanced Header with Actions
              _buildFormHeader(theme, isSmallScreen, isEditing, isLoading.value, handleSubmit, onCancel),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? _kSmallSpacing : _kSpacing),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isEditing) ...[
                          _SearchSection(
                            searchController: controllers['search']!,
                            onSearch: handleOrderSearch,
                            isSearching: isSearchingOrder.value,
                            recentOrders: recentOrders.value,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? _kSmallSpacing : _kSpacing),
                        ],
                        _BasicDetailsSection(
                          orderIdController: controllers['orderId']!,
                          customerNameController: controllers['customerName']!,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? _kSmallSpacing : _kSpacing),
                        _StatusSection(
                          orderStatus: orderStatus,
                          status: status,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? _kSmallSpacing : _kSpacing),
                        _AdditionalDetailsSection(
                          designUrlController: controllers['designUrl']!,
                          trackingIdController: controllers['trackingId']!,
                          isSmallScreen: isSmallScreen,
                        ),
                        if (products.value.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? _kSmallSpacing : _kSpacing),
                          _ProductsSection(
                            products: products.value,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader(
    ThemeData theme,
    bool isSmallScreen,
    bool isEditing,
    bool isLoading,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? _kSmallSpacing : _kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_kBorderRadius),
            ),
            child: Icon(
              isEditing ? Iconsax.edit : Iconsax.add,
              size: isSmallScreen ? _kSmallIconSize : _kIconSize,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit Order' : 'Create New Order',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}

// Extracted Widgets for Better Organization and Performance
class _SearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final bool isSearching;
  final List<String> recentOrders;
  final bool isSmallScreen;

  const _SearchSection({
    required this.searchController,
    required this.onSearch,
    required this.isSearching,
    required this.recentOrders,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _FormCard(
      title: 'Search WooCommerce Order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            controller: searchController,
            onSearch: onSearch,
            isSearching: isSearching,
          ),
          if (recentOrders.isNotEmpty) ...[
            const SizedBox(height: OrderForm._kSpacing),
            Text(
              'Recent Orders:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _RecentOrdersChips(
              recentOrders: recentOrders,
              onOrderSelected: (orderId) {
                searchController.text = orderId;
                onSearch();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isSearching;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'WooCommerce Order ID',
              prefixIcon: Icon(Iconsax.search_normal),
            ),
            onFieldSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: OrderForm._kSpacing),
        FilledButton.icon(
          onPressed: isSearching ? null : onSearch,
          icon: isSearching 
            ? const _LoadingIndicator()
            : const Icon(Iconsax.search_normal),
          label: Text(isSearching ? 'Searching...' : 'Search'),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _RecentOrdersChips extends StatelessWidget {
  final List<String> recentOrders;
  final Function(String) onOrderSelected;

  const _RecentOrdersChips({
    required this.recentOrders,
    required this.onOrderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recentOrders.map((orderId) => ActionChip(
        label: Text('#$orderId'),
        onPressed: () => onOrderSelected(orderId),
      )).toList(),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(OrderForm._kCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: OrderForm._kSpacing),
            child,
          ],
        ),
      ),
    );
  }
}

// Helper Functions
Map<String, TextEditingController> _createControllers(Map<String, dynamic>? initialData) => {
  'orderId': TextEditingController(text: initialData?['orderId']?.toString() ?? ''),
  'customerName': TextEditingController(text: initialData?['customerName']?.toString() ?? ''),
  'trackingId': TextEditingController(text: initialData?['trackingId']?.toString() ?? ''),
  'designUrl': TextEditingController(text: initialData?['designUrl']?.toString() ?? ''),
  'search': TextEditingController(),
};

void _disposeControllers(Map<String, TextEditingController> controllers) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
}

Function() _createOrderSearchHandler(
  WidgetRef ref,
  bool Function() mounted,
  Map<String, TextEditingController> controllers,
  ValueNotifier<String> orderStatus,
  ValueNotifier<String> status,
  ValueNotifier<List<Map<String, dynamic>>> products,
  BuildContext context,
  ThemeData theme,
) {
  return () async {
      final orderId = controllers['search']!.text;
      if (orderId.isEmpty) return;

      try {
        final orderData = await ref.read(wooOrderProvider(orderId).future);
        
        if (mounted()) {
          controllers['orderId']!.text = orderData.orderId;
          controllers['customerName']!.text = orderData.customerName;
          orderStatus.value = orderData.orderstatus;
          status.value = orderData.status;
          products.value = orderData.products.map((p) => p.toJson()).toList();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${orderData.products.length} products'),
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
    }
  };
}

Function() _createSubmitHandler(
  GlobalKey<FormState> formKey,
  ValueNotifier<bool> isLoading,
  Map<String, TextEditingController> controllers,
  ValueNotifier<String> orderStatus,
  ValueNotifier<String> status,
  ValueNotifier<List<Map<String, dynamic>>> products,
  Function(Map<String, dynamic>) onSubmit,
  bool Function() mounted,
) {
  return () async {
      if (formKey.currentState?.validate() ?? false) {
        isLoading.value = true;
        try {
          final formData = {
            'orderId': controllers['orderId']!.text,
            'customerName': controllers['customerName']!.text,
            'trackingId': controllers['trackingId']!.text,
            'designUrl': controllers['designUrl']!.text,
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
  };
}

Future<void> _fetchRecentOrders(ValueNotifier<List<String>> recentOrders) async {
  // TODO: Implement fetching recent orders from WooCommerce
  recentOrders.value = ['12345', '12346', '12347', '12348', '12349'];
}

class _BasicDetailsSection extends StatelessWidget {
  final TextEditingController orderIdController;
  final TextEditingController customerNameController;
  final bool isSmallScreen;

  const _BasicDetailsSection({
    required this.orderIdController,
    required this.customerNameController,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Basic Details',
      child: Row(
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
          const SizedBox(width: OrderForm._kSpacing),
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
  );
}
}

class _StatusSection extends StatelessWidget {
  final ValueNotifier<String> orderStatus;
  final ValueNotifier<String> status;
  final bool isSmallScreen;

  const _StatusSection({
    required this.orderStatus,
    required this.status,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Status Information',
      child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                _buildStatusDropdown(
                      value: orderStatus.value,
                  label: 'Payment Status',
                  icon: Iconsax.money,
                  items: const ['Prepaid', 'COD'],
                  onChanged: (value) => orderStatus.value = value!,
                ),
                const SizedBox(height: OrderForm._kSpacing),
                _buildStatusDropdown(
                      value: status.value,
                  label: 'Order Status',
                  icon: Iconsax.status,
                  items: const ['pending', 'completed'],
                  onChanged: (value) => status.value = value!,
                    ),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                  child: _buildStatusDropdown(
                        value: orderStatus.value,
                    label: 'Payment Status',
                    icon: Iconsax.money,
                    items: const ['Prepaid', 'COD'],
                    onChanged: (value) => orderStatus.value = value!,
                  ),
                ),
                const SizedBox(width: OrderForm._kSpacing),
                    Expanded(
                  child: _buildStatusDropdown(
                        value: status.value,
                    label: 'Order Status',
                    icon: Iconsax.status,
                    items: const ['pending', 'completed'],
                    onChanged: (value) => status.value = value!,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

class _AdditionalDetailsSection extends StatelessWidget {
  final TextEditingController designUrlController;
  final TextEditingController trackingIdController;
  final bool isSmallScreen;

  const _AdditionalDetailsSection({
    required this.designUrlController,
    required this.trackingIdController,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Additional Information',
      child: Column(
        children: [
          TextFormField(
            controller: designUrlController,
            decoration: const InputDecoration(
              labelText: 'Design URL',
              prefixIcon: Icon(Iconsax.link),
            ),
          ),
          const SizedBox(height: OrderForm._kSpacing),
          TextFormField(
            controller: trackingIdController,
            decoration: const InputDecoration(
              labelText: 'Tracking/AWB Number',
              prefixIcon: Icon(Iconsax.truck),
            ),
          ),
        ],
    ),
  );
}
}

class _ProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isSmallScreen;

  const _ProductsSection({
    required this.products,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _FormCard(
      title: 'Products',
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
                '${products.length} items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: OrderForm._kSpacing),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => ProductCard(
              product: products[index],
            ),
          ),
        ],
    ),
  );
}
} 