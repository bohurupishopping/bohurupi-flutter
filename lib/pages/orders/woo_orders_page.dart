// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iconsax/iconsax.dart';
import '../../components/woo_orders/woo_order_details_dialog.dart';
import '../../providers/orders/woo_orders_provider.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../components/woo_orders/woo_order_table.dart';

// Cache time provider for WooOrders with a const duration
final wooOrdersCacheTimeProvider = StateProvider<DateTime?>((ref) => null);

@immutable
class _PageStyles {
  final BoxDecoration pageDecoration;
  final BoxDecoration contentDecoration;
  final BoxDecoration headerDecoration;
  final BoxDecoration titleDecoration;
  final BoxDecoration searchDecoration;
  final BoxDecoration filterDecoration;
  final BoxDecoration countDecoration;
  final BoxDecoration buttonDecoration;
  final TextStyle titleStyle;
  final TextStyle labelStyle;
  final TextStyle searchStyle;
  final TextStyle searchHintStyle;
  final TextStyle countStyle;

  const _PageStyles({
    required this.pageDecoration,
    required this.contentDecoration,
    required this.headerDecoration,
    required this.titleDecoration,
    required this.searchDecoration,
    required this.filterDecoration,
    required this.countDecoration,
    required this.buttonDecoration,
    required this.titleStyle,
    required this.labelStyle,
    required this.searchStyle,
    required this.searchHintStyle,
    required this.countStyle,
  });

  factory _PageStyles.from(ThemeData theme, bool isSmallScreen) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity02 = theme.colorScheme.primary.withOpacity(0.2);
    final surfaceOpacity95 = theme.colorScheme.surface.withOpacity(0.95);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);
    final shadowOpacity01 = theme.colorScheme.shadow.withOpacity(0.1);

    return _PageStyles(
      pageDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
        ),
      ),
      contentDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineOpacity01),
        boxShadow: [
          BoxShadow(
            color: shadowOpacity01,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      headerDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: outlineOpacity01),
        ),
      ),
      titleDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: primaryOpacity02),
      ),
      searchDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outlineOpacity01),
      ),
      filterDecoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
      ),
      countDecoration: BoxDecoration(
        color: primaryOpacity01,
        borderRadius: BorderRadius.circular(20),
      ),
      buttonDecoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
      ),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: isSmallScreen ? 10 : 12,
      ) ?? const TextStyle(),
      searchStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      searchHintStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      countStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
        fontSize: isSmallScreen ? 10 : 12,
      ) ?? const TextStyle(),
    );
  }
}

@immutable
class WooOrdersPage extends HookConsumerWidget {
  const WooOrdersPage({super.key});

  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  // Memoized status color mapping
  static const Map<String, Color> _statusColors = {
    'pending': Colors.amber,
    'processing': Colors.blue,
    'on-hold': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'refunded': Colors.purple,
    'failed': Color(0xFFD32F2F),
  };

  static const List<String> _filterOptions = ['all', 'pending', 'processing', 'completed'];

  Color getStatusColor(String status) => _statusColors[status.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(wooOrdersProvider);
    final lastFetchTime = ref.watch(wooOrdersCacheTimeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final styles = _PageStyles.from(theme, isSmallScreen);

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
        searchDebouncer.value?.cancel();
        searchDebouncer.value = Timer(_debounceDelay, () {
          if (!isCacheValid()) {
            ref.read(wooOrdersProvider.notifier).fetchOrders();
            ref.read(wooOrdersCacheTimeProvider.notifier).state = DateTime.now();
          }
          ref.read(wooOrdersProvider.notifier).setSearchQuery(value);
        });
      },
      [isCacheValid],
    );

    // Cleanup debouncer on dispose
    useEffect(() {
      return () {
        searchDebouncer.value?.cancel();
      };
    }, const []);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: styles.pageDecoration,
            ),
            Container(
              margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
              decoration: styles.contentDecoration,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 8 : 12,
                    ),
                    decoration: styles.headerDecoration,
                    child: Column(
                      children: [
                        _buildHeaderTitle(styles, state, isSmallScreen, ref),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        _buildHeaderActions(styles, isSmallScreen, onSearch, onRefresh, state, ref),
                      ],
                    ),
                  ),
                  Expanded(
                    child: WooOrderTable(
                      orders: state.orders,
                      isLoading: state.isLoading,
                      isSmallScreen: isSmallScreen,
                      onOrderSelect: (orderJson) {
                        ref.read(wooOrdersProvider.notifier).selectOrder(orderJson);
                      },
                      onRefresh: onRefresh,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildHeaderTitle(_PageStyles styles, dynamic state, bool isSmallScreen, WidgetRef ref) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
          decoration: styles.titleDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                decoration: styles.buttonDecoration,
                child: FaIcon(
                  FontAwesomeIcons.store,
                  size: isSmallScreen ? 10 : 12,
                  color: styles.titleStyle.color,
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'WooCommerce Orders',
                style: styles.titleStyle,
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildPerPageDropdown(styles, state, isSmallScreen, ref),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _buildOrderCount(styles, state, isSmallScreen),
      ],
    );
  }

  Widget _buildHeaderActions(
    _PageStyles styles,
    bool isSmallScreen,
    Function(String) onSearch,
    Future<void> Function() onRefresh,
    dynamic state,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSearchField(styles, isSmallScreen, onSearch),
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _buildFilterButton(styles, isSmallScreen, state, ref),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _buildRefreshButton(styles, isSmallScreen, onRefresh),
      ],
    );
  }

  Widget _buildSearchField(_PageStyles styles, bool isSmallScreen, Function(String) onSearch) {
    return Container(
      height: isSmallScreen ? 32 : 36,
      decoration: styles.searchDecoration,
      child: TextField(
        onChanged: onSearch,
        style: styles.searchStyle,
        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: styles.searchHintStyle,
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: isSmallScreen ? 14 : 16,
            color: styles.searchHintStyle.color,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(_PageStyles styles, bool isSmallScreen, dynamic state, WidgetRef ref) {
    return FilledButton.tonal(
      onPressed: () => _showFilterBottomSheet(styles, state, ref),
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
            style: styles.labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(_PageStyles styles, bool isSmallScreen, Future<void> Function() onRefresh) {
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
            style: styles.labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildPerPageDropdown(_PageStyles styles, dynamic state, bool isSmallScreen, WidgetRef ref) {
    return Container(
      height: isSmallScreen ? 24 : 28,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6),
      decoration: styles.buttonDecoration,
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
                style: styles.labelStyle,
              ),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              ref.read(wooOrdersProvider.notifier).setPerPage(newValue);
            }
          },
          icon: Icon(
            Iconsax.arrow_down_1,
            size: isSmallScreen ? 12 : 14,
            color: styles.labelStyle.color?.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCount(_PageStyles styles, dynamic state, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: styles.countDecoration,
      child: Text(
        '${state.orders.length} Orders',
        style: styles.countStyle,
      ),
    );
  }

  void _showFilterBottomSheet(_PageStyles styles, dynamic state, WidgetRef ref) {
    showModalBottomSheet(
      context: ref.context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Orders',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._filterOptions.map((status) => _buildFilterOption(context, status, state, ref)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String status, dynamic state, WidgetRef ref) {
    final theme = Theme.of(context);
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
              : _statusColors[status]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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
              : _statusColors[status] ?? Colors.grey,
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
        ref.read(wooOrdersProvider.notifier).setStatusFilter(status);
        Navigator.pop(context);
      },
    );
  }
} 