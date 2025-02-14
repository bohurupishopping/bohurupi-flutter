import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../components/create_order/order_form.dart';
import '../../components/create_order/order_table.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../providers/orders/api_orders_provider.dart';
import '../../models/api_order.dart';

@immutable
class _PageStyles {
  final BoxDecoration pageDecoration;
  final BoxDecoration contentDecoration;
  final BoxDecoration headerDecoration;
  final BoxDecoration titleDecoration;
  final BoxDecoration buttonDecoration;
  final TextStyle titleStyle;
  final TextStyle labelStyle;

  const _PageStyles({
    required this.pageDecoration,
    required this.contentDecoration,
    required this.headerDecoration,
    required this.titleDecoration,
    required this.buttonDecoration,
    required this.titleStyle,
    required this.labelStyle,
  });

  factory _PageStyles.from(ThemeData theme, bool isSmallScreen) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity02 = theme.colorScheme.primary.withOpacity(0.2);
    final surfaceOpacity80 = theme.colorScheme.surface.withOpacity(0.8);
    final surfaceOpacity70 = theme.colorScheme.surface.withOpacity(0.7);

    return _PageStyles(
      pageDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.06),
            theme.colorScheme.tertiary.withOpacity(0.05),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      contentDecoration: BoxDecoration(
        color: surfaceOpacity80,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryOpacity01,
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
      headerDecoration: BoxDecoration(
        color: surfaceOpacity80,
        border: Border(
          bottom: BorderSide(
            color: primaryOpacity01,
            width: 0.5,
          ),
        ),
      ),
      titleDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.7),
            primaryOpacity01,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primaryOpacity02,
          width: 0.5,
        ),
      ),
      buttonDecoration: BoxDecoration(
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
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: isSmallScreen ? 10 : 12,
      ) ?? const TextStyle(),
    );
  }
}

class CreateOrderPage extends HookConsumerWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsyncValue = ref.watch(apiOrdersProvider(const ApiOrdersFilter()));
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Cache styles
    final styles = _PageStyles.from(theme, isSmallScreen);

    // State management using hooks
    final isTableView = useState(true);
    final orderDetails = useState<Map<String, dynamic>?>(null);
    final refreshKey = useState(GlobalKey<RefreshIndicatorState>());

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
      body: Container(
        decoration: styles.pageDecoration,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            child: Container(
              decoration: styles.contentDecoration,
              child: Column(
                children: [
                  _buildHeader(
                    theme: theme,
                    styles: styles,
                    isSmallScreen: isSmallScreen,
                    isTableView: isTableView,
                    orderDetails: orderDetails,
                    handleRefresh: handleRefresh,
                  ),
                  Expanded(
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
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader({
    required ThemeData theme,
    required _PageStyles styles,
    required bool isSmallScreen,
    required ValueNotifier<bool> isTableView,
    required ValueNotifier<Map<String, dynamic>?> orderDetails,
    required VoidCallback handleRefresh,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: styles.headerDecoration,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: styles.titleDecoration,
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
                    isTableView.value ? Iconsax.task_square : FontAwesomeIcons.plus,
                    size: isSmallScreen ? 10 : 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  isTableView.value ? 'Orders' : 'Create Order',
                  style: styles.titleStyle,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isTableView.value) ...[
            _buildRefreshButton(theme, styles, isSmallScreen, handleRefresh),
            SizedBox(width: isSmallScreen ? 6 : 8),
          ],
          Container(
            decoration: styles.buttonDecoration,
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
                    style: styles.labelStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(
    ThemeData theme,
    _PageStyles styles,
    bool isSmallScreen,
    VoidCallback onRefresh,
  ) {
    return Container(
      decoration: styles.buttonDecoration,
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
              style: styles.labelStyle,
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
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
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
                color: theme.colorScheme.error.withOpacity(0.1),
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