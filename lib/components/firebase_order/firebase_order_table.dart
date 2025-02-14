// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/firebase_order.dart';
import 'firebase_order_details_dialog.dart';
import '../orders/order_tracking_dialog.dart';

@immutable
class FirebaseOrderTableUtils {
  const FirebaseOrderTableUtils._();

  static final _dateFormatter = DateFormat('MMM d, y');
  static final Map<String, String> _dateCache = {};
  
  static final _statusColors = {
    'pending': const Color(0xFFFFA726), // Soft Orange
    'completed': const Color(0xFF66BB6A), // Soft Green
    'default': const Color(0xFF9E9E9E), // Neutral Gray
  };

  static final _orderStatusColors = {
    'cod': const Color(0xFF5C6BC0), // Soft Indigo
    'prepaid': const Color(0xFF26A69A), // Soft Teal
    'default': const Color(0xFF9E9E9E), // Neutral Gray
  };

  static Color getStatusColor(String status) {
    return _statusColors[status.toLowerCase()] ?? _statusColors['default']!;
  }

  static Color getOrderStatusColor(String status) {
    return _orderStatusColors[status.toLowerCase()] ?? _orderStatusColors['default']!;
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    return _dateCache.putIfAbsent(dateStr, () {
      try {
        final date = DateTime.parse(dateStr);
        return _dateFormatter.format(date);
      } catch (e) {
        debugPrint('Error formatting date: $e');
        return dateStr;
      }
    });
  }
}

@immutable
class _TableStyles {
  final BoxDecoration cardDecoration;
  final BoxDecoration productContainerDecoration;
  final BoxDecoration imageContainerDecoration;
  final BoxDecoration orderIdDecoration;
  final BoxDecoration dateDecoration;
  final TextStyle titleStyle;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle dateStyle;
  final TextStyle orderIdStyle;

  const _TableStyles({
    required this.cardDecoration,
    required this.productContainerDecoration,
    required this.imageContainerDecoration,
    required this.orderIdDecoration,
    required this.dateDecoration,
    required this.titleStyle,
    required this.labelStyle,
    required this.valueStyle,
    required this.dateStyle,
    required this.orderIdStyle,
  });

  factory _TableStyles.from(ThemeData theme) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity02 = theme.colorScheme.primary.withOpacity(0.2);
    final surfaceOpacity95 = theme.colorScheme.surface.withOpacity(0.95);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);

    return _TableStyles(
      cardDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryOpacity01, width: 0.5),
      ),
      productContainerDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryOpacity01, width: 0.5),
      ),
      imageContainerDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outlineOpacity01),
      ),
      orderIdDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryOpacity02, width: 0.5),
      ),
      dateDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ) ?? const TextStyle(),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ) ?? const TextStyle(),
      valueStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ) ?? const TextStyle(),
      dateStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ) ?? const TextStyle(),
      orderIdStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ) ?? const TextStyle(),
    );
  }
}

class FirebaseOrderTable extends StatelessWidget {
  final List<FirebaseOrder> orders;
  final bool isLoading;
  final String? error;
  final Function(int)? onPageChanged;
  final int currentPage;
  final int totalPages;

  const FirebaseOrderTable({
    super.key,
    required this.orders,
    required this.isLoading,
    this.error,
    this.onPageChanged,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingState();
    if (error != null) return _ErrorState(error: error!);
    if (orders.isEmpty) return const _EmptyState();

    final styles = _TableStyles.from(Theme.of(context));

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return _OptimizedOrderCard(
                        key: ValueKey(order.id),
                        order: order,
                        onViewDetails: () => _showOrderDetails(context, order),
                        styles: styles,
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (totalPages > 1)
          _OptimizedPagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }

  void _showOrderDetails(BuildContext context, FirebaseOrder order) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => FirebaseOrderDetailsDialog(
        order: order,
        isOpen: true,
        onOpenChange: (isOpen) {
          if (!isOpen) Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
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
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
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
              FontAwesomeIcons.box,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any orders at the moment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptimizedOrderCard extends StatelessWidget {
  final FirebaseOrder order;
  final VoidCallback onViewDetails;
  final _TableStyles styles;

  const _OptimizedOrderCard({
    Key? key,
    required this.order,
    required this.onViewDetails,
    required this.styles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pre-compute values outside the build method
    final formattedDate = FirebaseOrderTableUtils.formatDate(order.createdAt);
    final statusColor = FirebaseOrderTableUtils.getStatusColor(order.status);
    final orderStatusColor = FirebaseOrderTableUtils.getOrderStatusColor(order.orderstatus);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: styles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OptimizedHeader(
                    orderId: order.orderId,
                    date: formattedDate ?? 'N/A',
                    status: order.status,
                    statusColor: statusColor,
                    paymentMethod: order.orderstatus,
                    orderStatusColor: orderStatusColor,
                    styles: styles,
                  ),
                  if (order.products.isNotEmpty)
                    _OptimizedProductList(
                      products: order.products,
                      styles: styles,
                    ),
                  _OptimizedFooter(
                    trackingId: order.trackingId,
                    onViewDetails: onViewDetails,
                    styles: styles,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptimizedHeader extends StatelessWidget {
  final String orderId;
  final String date;
  final String status;
  final String paymentMethod;
  final Color statusColor;
  final Color orderStatusColor;
  final _TableStyles styles;

  const _OptimizedHeader({
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.paymentMethod,
    required this.orderStatusColor,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: styles.orderIdDecoration,
            child: Text(
              '#$orderId',
              style: styles.orderIdStyle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: styles.valueStyle.copyWith(
                color: statusColor,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: orderStatusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: orderStatusColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              paymentMethod.toUpperCase(),
              style: styles.valueStyle.copyWith(
                color: orderStatusColor,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: styles.dateDecoration,
            child: Text(date, style: styles.dateStyle),
          ),
        ],
      ),
    );
  }
}

class _OptimizedProductList extends StatelessWidget {
  final List<FirebaseOrderProduct> products;
  final _TableStyles styles;

  const _OptimizedProductList({
    required this.products,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: styles.productContainerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final product in products)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (product.image.isNotEmpty)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: styles.imageContainerDecoration,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error_outline,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.details,
                          style: styles.titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quantity: ${product.qty}',
                          style: styles.labelStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptimizedFooter extends StatelessWidget {
  final String? trackingId;
  final VoidCallback onViewDetails;
  final _TableStyles styles;

  const _OptimizedFooter({
    required this.trackingId,
    required this.onViewDetails,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onViewDetails,
            icon: Icon(
              Icons.visibility_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'View Details',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trackingId != null) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  builder: (context) => OrderTrackingDialog(
                    trackingId: trackingId!,
                    isOpen: true,
                    onOpenChange: (isOpen) {
                      if (!isOpen) Navigator.of(context).pop();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Track'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptimizedPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageChanged;

  const _OptimizedPagination({
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => onPageChanged?.call(currentPage - 1)
                : null,
          ),
          Text('$currentPage / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => onPageChanged?.call(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
} 