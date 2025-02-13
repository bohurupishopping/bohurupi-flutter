import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/woo_order.dart';

class WooOrderTable extends ConsumerStatefulWidget {
  final List<WooOrder> orders;
  final bool isLoading;
  final Function(Map<String, dynamic>) onOrderSelect;
  final bool isSmallScreen;
  final Future<void> Function()? onRefresh;

  const WooOrderTable({
    super.key,
    required this.orders,
    required this.isLoading,
    required this.onOrderSelect,
    required this.isSmallScreen,
    this.onRefresh,
  });

  @override
  ConsumerState<WooOrderTable> createState() => _WooOrderTableState();
}

class _WooOrderTableState extends ConsumerState<WooOrderTable> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  // Memoized status color mapping for better performance
  static final Map<String, Color> _statusColors = {
    'pending': Colors.amber,
    'processing': Colors.blue,
    'on-hold': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'refunded': Colors.purple,
    'failed': Colors.red.shade700,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) => _statusColors[status.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return _buildLoadingState(theme);
    }

    if (widget.orders.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      displacement: 20,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 8 : 16),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: widget.orders.length,
              itemBuilder: (context, index, animation) {
                final order = widget.orders[index];
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: _OrderCard(
                    key: ValueKey(order.id),
                    order: order,
                    statusColor: _getStatusColor(order.status),
                    isSmallScreen: widget.isSmallScreen,
                    onTap: () => widget.onOrderSelect(order.toJson()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 40,
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final WooOrder order;
  final Color statusColor;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _OrderCard({
    super.key,
    required this.order,
    required this.statusColor,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'order-${order.id}',
      child: Card(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildCustomerInfo(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            FontAwesomeIcons.boxOpen,
            size: isSmallScreen ? 14 : 16,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #${order.number}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                DateFormat('MMM d, y').format(
                  DateTime.parse(order.dateCreated),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme),
      ],
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.user,
                  size: isSmallScreen ? 12 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    '${order.billing.firstName} ${order.billing.lastName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8,
              vertical: isSmallScreen ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${order.currency} ${order.total}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallScreen ? 4 : 6,
            height: isSmallScreen ? 4 : 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Text(
            order.status.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: isSmallScreen ? 9 : 11,
            ),
          ),
        ],
      ),
    );
  }
} 