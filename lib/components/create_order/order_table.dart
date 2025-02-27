// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/api_order.dart';
import '../orders/order_tracking_dialog.dart';

class OrderTable extends StatelessWidget {
  final List<ApiOrder> orders;
  final Function(ApiOrder order)? onEdit;
  final Function(String orderId)? onDelete;
  final Function(String orderId, String newStatus)? onStatusChange;
  final bool readOnly;
  final bool isLoading;
  final String? error;

  const OrderTable({
    super.key,
    required this.orders,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.readOnly = false,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return _buildErrorView(theme, error!);
    }

    if (orders.isEmpty) {
      return _buildEmptyView(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int index = 0; index < orders.length; index++) ...[
              _OrderCard(
                order: orders[index],
                onEdit: onEdit,
                onDelete: onDelete,
                onStatusChange: onStatusChange,
                readOnly: readOnly,
                isSmallScreen: isSmallScreen,
              ),
              if (index < orders.length - 1) 
                const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildErrorView(ThemeData theme, String error) {
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

  Widget _buildEmptyView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.box,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any orders matching your criteria.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ApiOrder order;
  final Function(ApiOrder order)? onEdit;
  final Function(String orderId)? onDelete;
  final Function(String orderId, String newStatus)? onStatusChange;
  final bool readOnly;
  final bool isSmallScreen;

  const _OrderCard({
    required this.order,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.readOnly = false,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          _buildHeader(theme),

          // Products
          if (order.products.isNotEmpty)
            _buildProducts(theme),

          // Action Buttons
          if (!readOnly)
            _buildActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.box,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#${order.orderId}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusChip(theme, order.orderstatus),
                      const SizedBox(width: 8),
                      _buildStatusChip(theme, order.status),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer Info Row
          Row(
            children: [
              Icon(
                Iconsax.user,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.customerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProducts(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (int index = 0; index < order.products.length; index++) ...[
                _OrderProductCard(
                  product: order.products[index],
                  isSmallScreen: isSmallScreen,
                ),
                if (index < order.products.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (order.trackingId != null) ...[
            _buildActionButton(
              context,
              icon: Iconsax.truck,
              label: 'Track',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => OrderTrackingDialog(
                    trackingId: order.trackingId!,
                    isOpen: true,
                    onOpenChange: (isOpen) {
                      if (!isOpen) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          _buildActionButton(
            context,
            icon: Iconsax.edit,
            label: 'Edit',
            onPressed: () => onEdit?.call(order),
          ),
          const SizedBox(width: 8),
          _buildDeleteButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    final isPaymentStatus = status.toLowerCase() == 'cod' || status.toLowerCase() == 'prepaid';
    final color = isPaymentStatus
        ? status.toLowerCase() == 'cod'
            ? theme.colorScheme.error
            : theme.colorScheme.tertiary
        : status.toLowerCase() == 'pending'
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          textStyle: theme.textTheme.labelSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            if (!isSmallScreen) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 32,
      child: FilledButton.tonal(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Order'),
              content: Text('Are you sure you want to delete order #${order.orderId}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete?.call(order.id!);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          textStyle: theme.textTheme.labelSmall,
          backgroundColor: theme.colorScheme.error.withOpacity(0.1),
          foregroundColor: theme.colorScheme.error,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.trash, size: 14),
            if (!isSmallScreen) ...[
              const SizedBox(width: 4),
              const Text(
                'Delete',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderProductCard extends StatelessWidget {
  final ApiOrderProduct product;
  final bool isSmallScreen;

  const _OrderProductCard({
    required this.product,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageSize = isSmallScreen ? 40.0 : 48.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (product.image.isNotEmpty)
              SizedBox(
                width: imageSize,
                height: imageSize,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: imageSize,
                          height: imageSize,
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Iconsax.image, size: 24),
                        );
                      },
                    ),
                  ),
                ),
              ),

            SizedBox(width: isSmallScreen ? 8 : 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildAttributeChip(
                        context,
                        label: 'SKU: ${product.sku}',
                        icon: Iconsax.barcode,
                      ),
                      _buildAttributeChip(
                        context,
                        label: 'Qty: ${product.qty}',
                        icon: Iconsax.box,
                      ),
                      if (product.colour.isNotEmpty)
                        _buildAttributeChip(
                          context,
                          label: product.colour,
                          icon: Iconsax.color_swatch,
                        ),
                      if (product.size.isNotEmpty)
                        _buildAttributeChip(
                          context,
                          label: product.size,
                          icon: Iconsax.ruler,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: isSmallScreen ? 8 : 12),

            // Price
            Text(
              '₹${product.salePrice}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final fontSize = isSmallScreen ? 9.0 : 10.0;
    final iconSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen 
      ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
      : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 