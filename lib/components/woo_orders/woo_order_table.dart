import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/woo_order.dart';

@immutable
class _TableStyles {
  final BoxDecoration cardDecoration;
  final BoxDecoration headerDecoration;
  final BoxDecoration customerInfoDecoration;
  final BoxDecoration statusBadgeDecoration;
  final BoxDecoration iconContainerDecoration;
  final BoxDecoration priceBadgeDecoration;
  final TextStyle titleStyle;
  final TextStyle dateStyle;
  final TextStyle customerNameStyle;
  final TextStyle statusStyle;
  final TextStyle priceStyle;

  const _TableStyles({
    required this.cardDecoration,
    required this.headerDecoration,
    required this.customerInfoDecoration,
    required this.statusBadgeDecoration,
    required this.iconContainerDecoration,
    required this.priceBadgeDecoration,
    required this.titleStyle,
    required this.dateStyle,
    required this.customerNameStyle,
    required this.statusStyle,
    required this.priceStyle,
  });

  factory _TableStyles.from(ThemeData theme, bool isSmallScreen) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity015 = theme.colorScheme.primary.withOpacity(0.15);
    final surfaceOpacity95 = theme.colorScheme.surface.withOpacity(0.95);

    return _TableStyles(
      cardDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      headerDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      customerInfoDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      statusBadgeDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      iconContainerDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      priceBadgeDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryOpacity01,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: isSmallScreen ? 12 : 14,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      dateStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        fontSize: isSmallScreen ? 10 : 12,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      customerNameStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.8),
        fontSize: isSmallScreen ? 11 : 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      statusStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontSize: isSmallScreen ? 8 : 10,
      ) ?? const TextStyle(),
      priceStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
        fontSize: isSmallScreen ? 11 : 13,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
    );
  }
}

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
    final styles = _TableStyles.from(theme, widget.isSmallScreen);

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
                  child: RepaintBoundary(
                    child: _OrderCard(
                      key: ValueKey(order.id),
                      order: order,
                      statusColor: _getStatusColor(order.status),
                      isSmallScreen: widget.isSmallScreen,
                      onTap: () => widget.onOrderSelect(order.toJson()),
                      styles: styles,
                    ),
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading orders...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.boxOpen,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Orders Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyLarge?.copyWith(
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
  final _TableStyles styles;

  const _OrderCard({
    super.key,
    required this.order,
    required this.statusColor,
    required this.isSmallScreen,
    required this.onTap,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'order-${order.id}',
      child: Card(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: styles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  _buildCustomerInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: styles.headerDecoration,
          child: FaIcon(
            FontAwesomeIcons.boxOpen,
            size: isSmallScreen ? 12 : 14,
            color: statusColor,
          ),
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #${order.number}',
                style: styles.titleStyle,
              ),
              SizedBox(height: isSmallScreen ? 1 : 2),
              Text(
                DateFormat('MMM d, y').format(
                  DateTime.parse(order.dateCreated),
                ),
                style: styles.dateStyle,
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: styles.customerInfoDecoration,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                  decoration: styles.iconContainerDecoration,
                  child: FaIcon(
                    FontAwesomeIcons.user,
                    size: isSmallScreen ? 10 : 12,
                    color: statusColor,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    '${order.billing.firstName} ${order.billing.lastName}',
                    style: styles.customerNameStyle,
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
            decoration: styles.priceBadgeDecoration,
            child: Text(
              '${order.currency} ${order.total}',
              style: styles.priceStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: styles.statusBadgeDecoration.copyWith(
        color: statusColor.withOpacity(0.1),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 0.5,
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
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 3 : 4),
          Text(
            order.status.toUpperCase(),
            style: styles.statusStyle.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
} 