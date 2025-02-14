import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:ui';
import '../../components/create_order/order_form.dart';
import '../../components/create_order/order_table.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../providers/orders/api_orders_provider.dart';
import '../../models/api_order.dart';

@immutable
class _ThemeColors {
  final Color primaryOpacity01;
  final Color primaryOpacity05;
  final Color outlineOpacity01;
  final Color shadowOpacity05;
  final Color onSurfaceOpacity06;
  final Color surfaceOpacity80;
  final Color surfaceOpacity70;

  const _ThemeColors({
    required this.primaryOpacity01,
    required this.primaryOpacity05,
    required this.outlineOpacity01,
    required this.shadowOpacity05,
    required this.onSurfaceOpacity06,
    required this.surfaceOpacity80,
    required this.surfaceOpacity70,
  });
}

class CreateOrderPage extends HookConsumerWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsyncValue = ref.watch(apiOrdersProvider(const ApiOrdersFilter()));
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Animation controller for background effects
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 1500),
    );

    // Background animation
    final backgroundAnimation = useAnimation(
      Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Start the infinite animation
    useEffect(() {
      animationController.repeat(reverse: true);
      return null;
    }, const []);

    // State management using hooks
    final isTableView = useState(true);
    final orderDetails = useState<Map<String, dynamic>?>(null);
    final refreshKey = useState(GlobalKey<RefreshIndicatorState>());

    // Memoize theme-dependent colors
    final colors = useMemoized(
      () => _ThemeColors(
        primaryOpacity01: theme.colorScheme.primary.withOpacity(0.1),
        primaryOpacity05: theme.colorScheme.primary.withOpacity(0.05),
        outlineOpacity01: theme.colorScheme.outline.withOpacity(0.1),
        shadowOpacity05: theme.colorScheme.shadow.withOpacity(0.05),
        onSurfaceOpacity06: theme.colorScheme.onSurface.withOpacity(0.6),
        surfaceOpacity80: theme.colorScheme.surface.withOpacity(0.8),
        surfaceOpacity70: theme.colorScheme.surface.withOpacity(0.7),
      ),
      [theme],
    );

    // Load orders on first build using useEffect for better performance
    useEffect(() {
      Future.microtask(() {
        ref.invalidate(apiOrdersProvider(const ApiOrdersFilter()));
      });
      return null;
    }, const []);

    // Memoize callbacks to prevent unnecessary rebuilds
    final handleRefresh = useCallback(() async {
      ref.invalidate(apiOrdersProvider(const ApiOrdersFilter()));
    }, const []);

    final handleOrderSubmit = useCallback(
      (Map<String, dynamic> data) async {
        try {
          final mutations = ref.read(apiOrderMutationsProvider);
          if (orderDetails.value != null && orderDetails.value!['id'] != null) {
            await mutations.updateOrder(orderDetails.value!['id'], data);
          } else {
            await mutations.createOrder(data);
          }
          isTableView.value = true;
          orderDetails.value = null;
          refreshKey.value.currentState?.show();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      const [],
    );

    final handleOrderDelete = useCallback(
      (String orderId) async {
        try {
          final mutations = ref.read(apiOrderMutationsProvider);
          await mutations.deleteOrder(orderId);
          refreshKey.value.currentState?.show();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      const [],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1 * backgroundAnimation),
                      theme.colorScheme.secondary.withOpacity(0.12 * backgroundAnimation),
                      theme.colorScheme.tertiary.withOpacity(0.1 * backgroundAnimation),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  backgroundBlendMode: BlendMode.overlay,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 30 * backgroundAnimation,
                    sigmaY: 30 * backgroundAnimation,
                  ),
                  child: Container(
                    color: theme.colorScheme.background.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),

          // Main content with glassmorphism
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.surfaceOpacity80,
                          colors.surfaceOpacity70,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHeader(
                          theme: theme,
                          colors: colors,
                          isSmallScreen: isSmallScreen,
                          isTableView: isTableView,
                          orderDetails: orderDetails,
                          handleRefresh: handleRefresh,
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: ordersAsyncValue.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, stack) => _buildErrorView(theme, error, handleRefresh),
                                data: (response) => isTableView.value
                                  ? RefreshIndicator(
                                      key: refreshKey.value,
                                      onRefresh: handleRefresh,
                                      child: CustomScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        slivers: [
                                          SliverPadding(
                                            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                                            sliver: SliverToBoxAdapter(
                                              child: OrderTable(
                                                orders: response.orders,
                                                onEdit: (order) {
                                                  orderDetails.value = order.toJson();
                                                  isTableView.value = false;
                                                },
                                                onDelete: handleOrderDelete,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          OrderForm(
                                            initialData: orderDetails.value,
                                            onSubmit: handleOrderSubmit,
                                            onCancel: () {
                                              orderDetails.value = null;
                                              isTableView.value = true;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader({
    required ThemeData theme,
    required _ThemeColors colors,
    required bool isSmallScreen,
    required ValueNotifier<bool> isTableView,
    required ValueNotifier<Map<String, dynamic>?> orderDetails,
    required VoidCallback handleRefresh,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceOpacity80,
                colors.surfaceOpacity70,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                      theme.colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            theme.colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTableView.value ? Iconsax.task_square : FontAwesomeIcons.plus,
                        size: isSmallScreen ? 10 : 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      isTableView.value ? 'Orders' : 'Create Order',
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
              if (isTableView.value) ...[
                _buildRefreshButton(theme, isSmallScreen, handleRefresh),
                SizedBox(width: isSmallScreen ? 6 : 8),
              ],
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondaryContainer.withOpacity(0.7),
                      theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: FilledButton.tonal(
                  onPressed: () {
                    isTableView.value = !isTableView.value;
                    if (isTableView.value) {
                      orderDetails.value = null;
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
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
                        isTableView.value ? FontAwesomeIcons.plus : Iconsax.task_square,
                        size: isSmallScreen ? 10 : 12,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        isTableView.value ? 'Create New' : 'View Orders',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme, bool isSmallScreen, VoidCallback onRefresh) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withOpacity(0.7),
            theme.colorScheme.secondaryContainer.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: FilledButton.tonal(
        onPressed: onRefresh,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
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
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, Object error, VoidCallback onRefresh) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.errorContainer.withOpacity(0.1),
              theme.colorScheme.errorContainer.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.2),
            width: 0.5,
          ),
        ),
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
                fontWeight: FontWeight.bold,
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.error.withOpacity(0.2),
                    theme.colorScheme.error.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: FilledButton.tonal(
                onPressed: onRefresh,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 