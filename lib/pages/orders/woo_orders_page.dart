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
    'failed': Color(0xFFD32F2F), // Colors.red.shade700
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

    // Memoize theme-dependent colors
    final colors = useMemoized(
      () => _ThemeColors(
        primaryOpacity01: theme.colorScheme.primary.withOpacity(0.1),
        primaryOpacity05: theme.colorScheme.primary.withOpacity(0.05),
        outlineOpacity01: theme.colorScheme.outline.withOpacity(0.1),
        shadowOpacity05: theme.colorScheme.shadow.withOpacity(0.05),
        onSurfaceOpacity05: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      [theme],
    );
    
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
            _BackgroundGradient(theme: theme),
            _MainContent(
              theme: theme,
              state: state,
              isSmallScreen: isSmallScreen,
              colors: colors,
              onSearch: onSearch,
              onRefresh: onRefresh,
              filterOptions: _filterOptions,
              ref: ref,
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
}

@immutable
class _ThemeColors {
  final Color primaryOpacity01;
  final Color primaryOpacity05;
  final Color outlineOpacity01;
  final Color shadowOpacity05;
  final Color onSurfaceOpacity05;

  const _ThemeColors({
    required this.primaryOpacity01,
    required this.primaryOpacity05,
    required this.outlineOpacity01,
    required this.shadowOpacity05,
    required this.onSurfaceOpacity05,
  });
}

@immutable
class _BackgroundGradient extends StatelessWidget {
  final ThemeData theme;

  const _BackgroundGradient({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
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
    );
  }
}

@immutable
class _MainContent extends HookConsumerWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;
  final _ThemeColors colors;
  final Function(String) onSearch;
  final Future<void> Function() onRefresh;
  final List<String> filterOptions;
  final WidgetRef ref;

  const _MainContent({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
    required this.colors,
    required this.onSearch,
    required this.onRefresh,
    required this.filterOptions,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineOpacity01),
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
            _Header(
              theme: theme,
              state: state,
              isSmallScreen: isSmallScreen,
              onSearch: onSearch,
              onRefresh: onRefresh,
              filterOptions: filterOptions,
              ref: ref,
            ),
            Expanded(
              child: _OrdersList(
                theme: theme,
                state: state,
                isSmallScreen: isSmallScreen,
                ref: ref,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _Header extends StatelessWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;
  final Function(String) onSearch;
  final Future<void> Function() onRefresh;
  final List<String> filterOptions;
  final WidgetRef ref;

  const _Header({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
    required this.onSearch,
    required this.onRefresh,
    required this.filterOptions,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
          _HeaderTitle(
            theme: theme,
            state: state,
            isSmallScreen: isSmallScreen,
            ref: ref,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          _HeaderActions(
            theme: theme,
            isSmallScreen: isSmallScreen,
            onSearch: onSearch,
            onRefresh: onRefresh,
            filterOptions: filterOptions,
            state: state,
            ref: ref,
          ),
        ],
      ),
    );
  }
}

@immutable
class _HeaderTitle extends StatelessWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;
  final WidgetRef ref;

  const _HeaderTitle({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        _PerPageDropdown(
          theme: theme,
          state: state,
          isSmallScreen: isSmallScreen,
          ref: ref,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _OrderCount(
          theme: theme,
          state: state,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }
}

@immutable
class _HeaderActions extends StatelessWidget {
  final ThemeData theme;
  final bool isSmallScreen;
  final Function(String) onSearch;
  final Future<void> Function() onRefresh;
  final List<String> filterOptions;
  final dynamic state;
  final WidgetRef ref;

  const _HeaderActions({
    required this.theme,
    required this.isSmallScreen,
    required this.onSearch,
    required this.onRefresh,
    required this.filterOptions,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SearchField(
            theme: theme,
            isSmallScreen: isSmallScreen,
            onSearch: onSearch,
          ),
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _FilterButton(
          theme: theme,
          isSmallScreen: isSmallScreen,
          filterOptions: filterOptions,
          state: state,
          ref: ref,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _RefreshButton(
          theme: theme,
          isSmallScreen: isSmallScreen,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

@immutable
class _OrdersList extends StatelessWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;
  final WidgetRef ref;

  const _OrdersList({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
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

@immutable
class _PerPageDropdown extends StatelessWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;
  final WidgetRef ref;

  const _PerPageDropdown({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
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
              ref.read(wooOrdersProvider.notifier).setPerPage(newValue);
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
}

@immutable
class _OrderCount extends StatelessWidget {
  final ThemeData theme;
  final dynamic state;
  final bool isSmallScreen;

  const _OrderCount({
    required this.theme,
    required this.state,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

@immutable
class _SearchField extends StatelessWidget {
  final ThemeData theme;
  final bool isSmallScreen;
  final Function(String) onSearch;

  const _SearchField({
    required this.theme,
    required this.isSmallScreen,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

@immutable
class _FilterButton extends StatelessWidget {
  final ThemeData theme;
  final bool isSmallScreen;
  final List<String> filterOptions;
  final dynamic state;
  final WidgetRef ref;

  const _FilterButton({
    required this.theme,
    required this.isSmallScreen,
    required this.filterOptions,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => _showFilterBottomSheet(context),
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

  void _showFilterBottomSheet(BuildContext context) {
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
            ...filterOptions.map((status) => _buildFilterOption(context, status)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String status) {
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
              : WooOrdersPage._statusColors[status]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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
              : WooOrdersPage._statusColors[status] ?? Colors.grey,
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

@immutable
class _RefreshButton extends StatelessWidget {
  final ThemeData theme;
  final bool isSmallScreen;
  final Future<void> Function() onRefresh;

  const _RefreshButton({
    required this.theme,
    required this.isSmallScreen,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
} 