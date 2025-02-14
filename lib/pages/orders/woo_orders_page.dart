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
  static const double _smallScreenThreshold = 600;

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
    
    // Memoize screen size calculations
    final screenWidth = useMemoized(() => MediaQuery.of(context).size.width, [MediaQuery.of(context)]);
    final isSmallScreen = useMemoized(() => screenWidth < _smallScreenThreshold, [screenWidth]);
    
    // Memoize styles to prevent recalculation on every build
    final styles = useMemoized(() => _PageStyles.from(theme, isSmallScreen), [theme, isSmallScreen]);

    // Memoize cache validation function
    final isCacheValid = useCallback(() {
      if (lastFetchTime == null) return false;
      final now = DateTime.now();
      return now.difference(lastFetchTime) < _cacheDuration;
    }, [lastFetchTime]);

    // Debounced search controller
    final searchController = useTextEditingController();
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
    useEffect(() => () => searchDebouncer.value?.cancel(), const []);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _OptimizedPageContent(
          styles: styles,
          isSmallScreen: isSmallScreen,
          state: state,
          onSearch: onSearch,
          onRefresh: onRefresh,
          searchController: searchController,
        ),
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

@immutable
class _OptimizedPageContent extends StatelessWidget {
  final _PageStyles styles;
  final bool isSmallScreen;
  final dynamic state;
  final Function(String) onSearch;
  final Future<void> Function() onRefresh;
  final TextEditingController searchController;

  const _OptimizedPageContent({
    required this.styles,
    required this.isSmallScreen,
    required this.state,
    required this.onSearch,
    required this.onRefresh,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: styles.pageDecoration,
          ),
        ),
        Container(
          margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
          decoration: styles.contentDecoration,
          child: Column(
            children: [
              RepaintBoundary(
                child: _OptimizedHeader(
                  styles: styles,
                  isSmallScreen: isSmallScreen,
                  state: state,
                  onSearch: onSearch,
                  onRefresh: onRefresh,
                  searchController: searchController,
                ),
              ),
              Expanded(
                child: RepaintBoundary(
                  child: WooOrderTable(
                    orders: state.orders,
                    isLoading: state.isLoading,
                    onOrderSelect: (order) {
                      showDialog(
                        context: context,
                        useSafeArea: false,
                        builder: (context) => WooOrderDetailsDialog(
                          order: order,
                          isOpen: true,
                          onOpenChange: (isOpen) {
                            if (!isOpen) Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                    isSmallScreen: isSmallScreen,
                    onRefresh: onRefresh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedHeader extends StatelessWidget {
  final _PageStyles styles;
  final bool isSmallScreen;
  final dynamic state;
  final Function(String) onSearch;
  final Future<void> Function() onRefresh;
  final TextEditingController searchController;

  const _OptimizedHeader({
    required this.styles,
    required this.isSmallScreen,
    required this.state,
    required this.onSearch,
    required this.onRefresh,
    required this.searchController,
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
      decoration: styles.headerDecoration,
      child: Column(
        children: [
          _buildTitle(context),
          SizedBox(height: isSmallScreen ? 8 : 12),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: styles.titleDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.boxOpen,
                size: isSmallScreen ? 14 : 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text('WooCommerce Orders', style: styles.titleStyle),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: styles.countDecoration,
          child: Text(
            '${state.orders.length} Orders',
            style: styles.countStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isSmallScreen ? 36 : 40,
            decoration: styles.searchDecoration,
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              style: styles.searchStyle,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: styles.searchHintStyle,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  size: isSmallScreen ? 16 : 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildRefreshButton(context),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Container(
      height: isSmallScreen ? 36 : 40,
      decoration: styles.buttonDecoration,
      child: IconButton(
        onPressed: onRefresh,
        icon: Icon(
          Icons.refresh,
          size: isSmallScreen ? 18 : 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
        tooltip: 'Refresh Orders',
      ),
    );
  }
} 