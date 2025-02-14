// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../models/api_order.dart';
import '../orders/order_tracking_dialog.dart';

@immutable
class _ThemeColors {
  final Color primaryOpacity01;
  final Color primaryOpacity05;
  final Color outlineOpacity01;
  final Color errorOpacity01;
  final Color surfaceVariantOpacity03;
  final Color surfaceOpacity80;
  final Color surfaceOpacity70;

  const _ThemeColors({
    required this.primaryOpacity01,
    required this.primaryOpacity05,
    required this.outlineOpacity01,
    required this.errorOpacity01,
    required this.surfaceVariantOpacity03,
    required this.surfaceOpacity80,
    required this.surfaceOpacity70,
  });
}

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

    // Memoize theme-dependent colors
    final colors = _ThemeColors(
      primaryOpacity01: theme.colorScheme.primary.withOpacity(0.1),
      primaryOpacity05: theme.colorScheme.primary.withOpacity(0.05),
      outlineOpacity01: theme.colorScheme.outline.withOpacity(0.1),
      errorOpacity01: theme.colorScheme.error.withOpacity(0.1),
      surfaceVariantOpacity03: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      surfaceOpacity80: theme.colorScheme.surface.withOpacity(0.8),
      surfaceOpacity70: theme.colorScheme.surface.withOpacity(0.7),
    );

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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

    if (error != null) {
      return _ErrorView(
        theme: theme,
        error: error!,
        colors: colors,
      );
    }

    if (orders.isEmpty) {
      return _EmptyView(
        theme: theme,
        colors: colors,
      );
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
                theme: theme,
                colors: colors,
              ),
              if (index < orders.length - 1) 
                const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

@immutable
class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final String error;
  final _ThemeColors colors;

  const _ErrorView({
    required this.theme,
    required this.error,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
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
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error.withOpacity(0.2),
                        theme.colorScheme.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
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
        ),
      ),
    );
  }
}

@immutable
class _EmptyView extends StatelessWidget {
  final ThemeData theme;
  final _ThemeColors colors;

  const _EmptyView({
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.surfaceOpacity80,
                  colors.surfaceOpacity70,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                    Iconsax.box,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn\'t find any orders matching your criteria.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _OrderCard extends StatelessWidget {
  final ApiOrder order;
  final Function(ApiOrder order)? onEdit;
  final Function(String orderId)? onDelete;
  final Function(String orderId, String newStatus)? onStatusChange;
  final bool readOnly;
  final bool isSmallScreen;
  final ThemeData theme;
  final _ThemeColors colors;

  const _OrderCard({
    required this.order,
    required this.theme,
    required this.colors,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.readOnly = false,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.1),
              width: 0.5,
            ),
          ),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrderHeader(
                  order: order,
                  theme: theme,
                  colors: colors,
                ),
                if (order.products.isNotEmpty)
                  _OrderProducts(
                    products: order.products,
                    isSmallScreen: isSmallScreen,
                    theme: theme,
                    colors: colors,
                  ),
                if (!readOnly)
                  _OrderActions(
                    order: order,
                    theme: theme,
                    colors: colors,
                    isSmallScreen: isSmallScreen,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _OrderHeader extends StatelessWidget {
  final ApiOrder order;
  final ThemeData theme;
  final _ThemeColors colors;

  const _OrderHeader({
    required this.order,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.9),
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
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
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusChip(
                        status: order.orderstatus,
                        theme: theme,
                        colors: colors,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        status: order.status,
                        theme: theme,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  theme.colorScheme.surfaceVariant.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.user,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
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
          ),
        ],
      ),
    );
  }
}

@immutable
class _StatusChip extends StatelessWidget {
  final String status;
  final ThemeData theme;
  final _ThemeColors colors;

  const _StatusChip({
    required this.status,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isPaymentStatus = status.toLowerCase() == 'cod' || status.toLowerCase() == 'prepaid';
    final color = isPaymentStatus
        ? status.toLowerCase() == 'cod'
            ? theme.colorScheme.error
            : theme.colorScheme.tertiary
        : status.toLowerCase() == 'pending'
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
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
}

@immutable
class _OrderProducts extends StatelessWidget {
  final List<ApiOrderProduct> products;
  final bool isSmallScreen;
  final ThemeData theme;
  final _ThemeColors colors;

  const _OrderProducts({
    required this.products,
    required this.isSmallScreen,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.7),
            theme.colorScheme.surface.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < products.length; index++) ...[
            _OrderProductCard(
              product: products[index],
              isSmallScreen: isSmallScreen,
              theme: theme,
              colors: colors,
            ),
            if (index < products.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

@immutable
class _OrderProductCard extends StatelessWidget {
  final ApiOrderProduct product;
  final bool isSmallScreen;
  final ThemeData theme;
  final _ThemeColors colors;

  const _OrderProductCard({
    required this.product,
    required this.isSmallScreen,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = isSmallScreen ? 40.0 : 48.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceOpacity80,
                colors.surfaceOpacity70,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.image.isNotEmpty)
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.9),
                        theme.colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colors.surfaceVariantOpacity03,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colors.surfaceVariantOpacity03,
                        child: const Icon(Iconsax.image, size: 24),
                      ),
                    ),
                  ),
                ),

              SizedBox(width: isSmallScreen ? 8 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.details,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
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

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '₹${product.salePrice}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final fontSize = isSmallScreen ? 9.0 : 10.0;
    final iconSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen 
      ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
      : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 0.5,
        ),
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

@immutable
class _OrderActions extends StatelessWidget {
  final ApiOrder order;
  final ThemeData theme;
  final _ThemeColors colors;
  final bool isSmallScreen;
  final Function(ApiOrder)? onEdit;
  final Function(String)? onDelete;

  const _OrderActions({
    required this.order,
    required this.theme,
    required this.colors,
    required this.isSmallScreen,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.9),
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (order.trackingId != null) ...[
            _ActionButton(
              icon: Iconsax.truck,
              label: 'Track',
              isSmallScreen: isSmallScreen,
              theme: theme,
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
          _ActionButton(
            icon: Iconsax.edit,
            label: 'Edit',
            isSmallScreen: isSmallScreen,
            theme: theme,
            onPressed: () => onEdit?.call(order),
          ),
          const SizedBox(width: 8),
          _DeleteButton(
            order: order,
            theme: theme,
            colors: colors,
            isSmallScreen: isSmallScreen,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

@immutable
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSmallScreen;
  final ThemeData theme;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isSmallScreen,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
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
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
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
}

@immutable
class _DeleteButton extends StatelessWidget {
  final ApiOrder order;
  final ThemeData theme;
  final _ThemeColors colors;
  final bool isSmallScreen;
  final Function(String)? onDelete;

  const _DeleteButton({
    required this.order,
    required this.theme,
    required this.colors,
    required this.isSmallScreen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withOpacity(0.15),
            theme.colorScheme.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: FilledButton.tonal(
        onPressed: () => _showDeleteDialog(context),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          textStyle: theme.textTheme.labelSmall,
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.error.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error.withOpacity(0.2),
                      theme.colorScheme.error.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.trash,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Delete Order'),
            ],
          ),
          content: Text('Are you sure you want to delete order #${order.orderId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
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
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete?.call(order.id!);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 