// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../components/woo_orders/woo_order_details_dialog.dart';
import '../../providers/orders/woo_orders_provider.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../components/woo_orders/woo_order_table.dart';

// Cache time provider for WooOrders
final wooOrdersCacheTimeProvider = StateProvider<DateTime?>((ref) => null);

class WooOrdersPage extends HookConsumerWidget {
  const WooOrdersPage({super.key});

  static const Duration _cacheDuration = Duration(minutes: 5);

  // Memoized status color mapping
  static final Map<String, Color> _statusColors = {
    'pending': Colors.amber,
    'processing': Colors.blue,
    'on-hold': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'refunded': Colors.purple,
    'failed': Colors.red.shade700,
  };

  Color getStatusColor(String status) => _statusColors[status.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(wooOrdersProvider);
    final lastFetchTime = ref.watch(wooOrdersCacheTimeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
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
          ref.read(wooOrdersProvider.notifier).fetchOrders();
          ref.read(wooOrdersCacheTimeProvider.notifier).state = DateTime.now();
        });
      }
      return null;
    }, const []);

    // Memoize callbacks to prevent unnecessary rebuilds
    final onRefresh = useCallback(
      () async {
        await ref.read(wooOrdersProvider.notifier).fetchOrders();
        ref.read(wooOrdersCacheTimeProvider.notifier).state = DateTime.now();
      },
      const [],
    );

    final onSearch = useCallback(
      (String value) {
        // If the cache is invalid, fetch fresh data before searching
        if (!isCacheValid()) {
          ref.read(wooOrdersProvider.notifier).fetchOrders();
          ref.read(wooOrdersCacheTimeProvider.notifier).state = DateTime.now();
        }
        ref.read(wooOrdersProvider.notifier).setSearchQuery(value);
      },
      const [],
    );

    // Memoize the filter options to prevent rebuilds
    final filterOptions = useMemoized(
      () => ['all', 'pending', 'processing', 'completed'],
      const [],
    );

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
                    _buildHeader(
                      context,
                      theme,
                      state,
                      isSmallScreen,
                      onSearch,
                      onRefresh,
                      filterOptions,
                    ),
                    Expanded(
                      child: _buildOrdersList(
                        context,
                        theme,
                        state,
                        isSmallScreen,
                        ref,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Order Details Dialog
            if (state.isDialogOpen && state.selectedOrder != null)
              WooOrderDetailsDialog(
                order: state.selectedOrder!.toJson(),
                isOpen: state.isDialogOpen,
                onOpenChange: (isOpen) {
                  if (!isOpen) {
                    ref.read(wooOrdersProvider.notifier).closeDialog();
                  }
                },
              ),
          ],
        ),
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    bool isSmallScreen,
    Function(String) onSearch,
    Future<void> Function() onRefresh,
    List<String> filterOptions,
  ) {
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
        children: [
          Row(
            children: [
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
                      child: FaIcon(
                        FontAwesomeIcons.store,
                        size: isSmallScreen ? 10 : 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'WooCommerce Orders',
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
              _buildPerPageDropdown(context, theme, state, isSmallScreen),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.orders.length} Orders',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: isSmallScreen ? 32 : 36,
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
                    onChanged: onSearch,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      prefixIcon: Icon(
                        Iconsax.search_normal,
                        size: isSmallScreen ? 14 : 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              _buildFilterButton(context, theme, state, isSmallScreen, filterOptions),
              SizedBox(width: isSmallScreen ? 6 : 8),
              _buildRefreshButton(theme, isSmallScreen, onRefresh),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerPageDropdown(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    bool isSmallScreen,
  ) {
    return Container(
      height: isSmallScreen ? 24 : 28,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: state.perPage,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          items: [50, 100, 200].map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(
                '$value',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              ProviderScope.containerOf(context).read(wooOrdersProvider.notifier).setPerPage(newValue);
            }
          },
          icon: Icon(
            Iconsax.arrow_down_1,
            size: isSmallScreen ? 12 : 14,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    bool isSmallScreen,
    List<String> filterOptions,
  ) {
    return FilledButton.tonal(
      onPressed: () => _showFilterBottomSheet(
        context,
        theme,
        state,
        filterOptions,
      ),
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
            Iconsax.filter,
            size: isSmallScreen ? 10 : 12,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            'Filter',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(
    ThemeData theme,
    bool isSmallScreen,
    Future<void> Function() onRefresh,
  ) {
    return FilledButton.tonal(
      onPressed: onRefresh,
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

  void _showFilterBottomSheet(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    List<String> filterOptions,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Orders',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...filterOptions.map(
              (status) => _buildFilterOption(context, theme, state, status),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    String status,
  ) {
    return ListTile(
      selected: state.statusFilter == status,
      selectedColor: theme.colorScheme.primary,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: status == 'all'
              ? theme.colorScheme.primary.withOpacity(0.1)
              : getStatusColor(status).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: FaIcon(
          status == 'all'
              ? FontAwesomeIcons.list
              : status == 'pending'
                  ? FontAwesomeIcons.clock
                  : status == 'processing'
                      ? FontAwesomeIcons.spinner
                      : FontAwesomeIcons.check,
          size: 14,
          color: status == 'all'
              ? theme.colorScheme.primary
              : getStatusColor(status),
        ),
      ),
      title: Text(
        status == 'all'
            ? 'All Orders'
            : status.substring(0, 1).toUpperCase() + status.substring(1),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        final notifier = ProviderScope.containerOf(context).read(wooOrdersProvider.notifier);
        notifier.setStatusFilter(status);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    ThemeData theme,
    dynamic state,
    bool isSmallScreen,
    WidgetRef ref,
  ) {
    return WooOrderTable(
      orders: state.orders,
      isLoading: state.isLoading,
      isSmallScreen: isSmallScreen,
      onOrderSelect: (orderJson) {
        ref.read(wooOrdersProvider.notifier).selectOrder(orderJson);
      },
      onRefresh: () async {
        await ref.read(wooOrdersProvider.notifier).fetchOrders();
        ref.read(wooOrdersCacheTimeProvider.notifier).state = DateTime.now();
      },
    );
  }
} 