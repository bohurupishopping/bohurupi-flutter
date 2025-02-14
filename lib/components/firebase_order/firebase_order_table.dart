// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/firebase_order.dart';
import 'firebase_order_details_dialog.dart';
import '../orders/order_tracking_dialog.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

@immutable
class FirebaseOrderTableUtils {
  const FirebaseOrderTableUtils._();

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726); // Soft Orange
      case 'completed':
        return const Color(0xFF66BB6A); // Soft Green
      default:
        return const Color(0xFF9E9E9E); // Neutral Gray
    }
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cod':
        return const Color(0xFF5C6BC0); // Soft Indigo
      case 'prepaid':
        return const Color(0xFF26A69A); // Soft Teal
      default:
        return const Color(0xFF9E9E9E); // Neutral Gray
    }
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateStr;
    }
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
    final shadowOpacity01 = theme.colorScheme.shadow.withOpacity(0.1);

    return _TableStyles(
      cardDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryOpacity01, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: shadowOpacity01,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      productContainerDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryOpacity01,
          width: 0.5,
        ),
      ),
      imageContainerDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outlineOpacity01,
        ),
      ),
      orderIdDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryOpacity02,
          width: 0.5,
        ),
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
    final theme = Theme.of(context);
    final styles = _TableStyles.from(theme);

    if (isLoading) {
      return const _LoadingState();
    }

    if (error != null) {
      return _ErrorState(error: error!);
    }

    if (orders.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return RepaintBoundary(
                child: _OrderCard(
                  order: order,
                  onViewDetails: () {
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
                  },
                  styles: styles,
                ),
              );
            },
          ),
        ),
        if (totalPages > 1)
          _Pagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
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

class _OrderCard extends StatelessWidget {
  final FirebaseOrder order;
  final VoidCallback onViewDetails;
  final _TableStyles styles;

  const _OrderCard({
    required this.order,
    required this.onViewDetails,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = FirebaseOrderTableUtils.getStatusColor(order.status);
    final orderStatusColor = FirebaseOrderTableUtils.getOrderStatusColor(order.orderstatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: styles.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, statusColor, orderStatusColor),
              const SizedBox(height: 16),
              _buildProductsList(theme),
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color statusColor, Color orderStatusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderIdBadge(
                orderId: order.orderId,
                styles: styles,
              ),
              const SizedBox(width: 8),
              _DateBadge(
                date: order.createdAt,
                styles: styles,
              ),
              const SizedBox(height: 4),
              Text(
                order.customerName,
                style: styles.titleStyle,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _StatusBadge(
              text: order.status,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            _StatusBadge(
              text: order.orderstatus,
              color: orderStatusColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsList(ThemeData theme) {
    return Container(
      decoration: styles.productContainerDecoration,
      child: Column(
        children: [
          for (var i = 0; i < order.products.length; i++) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: _ProductListItem(
                product: order.products[i],
                styles: styles,
              ),
            ),
            if (i < order.products.length - 1)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: theme.colorScheme.outline.withOpacity(0.05),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        const Spacer(),
        _ViewDetailsButton(onPressed: onViewDetails),
        if (order.trackingId != null) ...[
          const SizedBox(width: 8),
          _TrackOrderButton(trackingId: order.trackingId!),
        ],
      ],
    );
  }
}

class _OrderIdBadge extends StatelessWidget {
  final String orderId;
  final _TableStyles styles;

  const _OrderIdBadge({
    required this.orderId,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: styles.orderIdDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '#$orderId',
            style: styles.orderIdStyle,
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String? date;
  final _TableStyles styles;

  const _DateBadge({
    this.date,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: styles.dateDecoration,
      child: Text(
        FirebaseOrderTableUtils.formatDate(date),
        style: styles.dateStyle,
      ),
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ViewDetailsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.visibility_outlined,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        'View Details',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}

class _TrackOrderButton extends StatelessWidget {
  final String trackingId;

  const _TrackOrderButton({required this.trackingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          useSafeArea: false,
          builder: (context) => OrderTrackingDialog(
            trackingId: trackingId,
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
        backgroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final dynamic product;
  final _TableStyles styles;

  const _ProductListItem({
    required this.product,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.image.isNotEmpty)
          Container(
            width: 48,
            height: 48,
            decoration: styles.imageContainerDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.errorContainer,
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.details,
                style: styles.titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _ProductDetail(
                    label: 'SKU',
                    value: product.sku,
                    styles: styles,
                  ),
                  _ProductDetail(
                    label: 'Qty',
                    value: product.qty.toString(),
                    styles: styles,
                  ),
                  _ProductDetail(
                    label: 'Price',
                    value: '₹${product.salePrice}',
                    isHighlighted: true,
                    styles: styles,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final _TableStyles styles;

  const _ProductDetail({
    required this.label,
    required this.value,
    required this.styles,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: styles.labelStyle,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => onPageChanged?.call(currentPage - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $currentPage of $totalPages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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