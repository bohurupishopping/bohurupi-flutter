// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

@immutable
class WooOrderUtils {
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  // Optimized color mappings with vibrant colors
  static final Map<String, Color> statusColors = {
    'pending': const Color(0xFFFFB74D),    // Vibrant Orange
    'processing': const Color(0xFF64B5F6),  // Bright Blue
    'on-hold': const Color(0xFFFFD54F),     // Warm Yellow
    'completed': const Color(0xFF81C784),   // Fresh Green
    'cancelled': const Color(0xFFE57373),   // Soft Red
    'refunded': const Color(0xFFBA68C8),    // Rich Purple
    'failed': const Color(0xFFEF5350),      // Deep Red
  };

  static final Map<String, Color> sectionColors = {
    'billing': const Color(0xFFF06292),     // Pink
    'shipping': const Color(0xFF7986CB),    // Indigo
    'payment': const Color(0xFF4DB6AC),     // Teal
    'summary': const Color(0xFFFFB300),     // Amber
    'note': const Color(0xFF64B5F6),        // Blue
  };

  // Cached date formatter for better performance
  static final _dateFormatter = DateFormat('MMM d, y h:mm a');
  static final Map<String, String> _dateCache = {};

  static String formatDate(String dateStr) {
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

  // Optimized utility methods with early returns and null checks
  static Map<String, String>? getProductUrls(List<dynamic>? metaData) {
    if (metaData == null || metaData.isEmpty) return null;

    final urls = <String, String>{};
    for (final meta in metaData) {
      final key = meta['key']?.toString() ?? '';
      if (key == '_product_url' || key == 'product_url') {
        urls['product_url'] = meta['value']?.toString() ?? '';
      } else if (key == '_download_url' || key == 'download_url') {
        urls['download_url'] = meta['value']?.toString() ?? '';
      }
      if (urls.length == 2) break; // Early exit if both URLs found
    }
    return urls.isEmpty ? null : urls;
  }

  static List<Map<String, String>> getVariants(List<dynamic>? metaData) {
    if (metaData == null || metaData.isEmpty) return const [];

    return metaData
      .where((meta) {
        final key = (meta['key']?.toString() ?? '').toLowerCase();
        return key.contains('size') || key == 'pa_size' ||
               key.contains('color') || key.contains('colour') || key == 'pa_color';
      })
      .map((meta) {
        final key = (meta['key']?.toString() ?? '').toLowerCase();
        return {
          'type': key.contains('size') ? 'size' : 'color',
          'label': key.contains('size') ? 'Size' : 'Color',
          'value': meta['value']?.toString() ?? '',
        };
      })
      .toList();
  }

  static List<Map<String, String>> getCustomization(List<dynamic>? metaData) {
    if (metaData == null || metaData.isEmpty) return const [];

    return metaData
      .where((meta) {
        final key = meta['key']?.toString() ?? '';
        return !key.startsWith('_') && 
               !key.contains('select_') &&
               !key.contains('size_') &&
               key != 'pa_size' &&
               key != 'pa_color';
      })
      .map((meta) => {
        'label': (meta['display_key']?.toString() ?? meta['key']?.toString() ?? '')
          .replaceAll('_', ' '),
        'value': meta['display_value']?.toString() ?? meta['value']?.toString() ?? '',
      })
      .toList();
  }

  static List<String> getCategories(List<dynamic>? metaData) {
    if (metaData == null || metaData.isEmpty) return const [];

    for (final meta in metaData) {
      if (meta['key'] == '_product_categories' || meta['key'] == 'product_categories') {
        try {
          final value = meta['value']?.toString() ?? '';
          if (value.isNotEmpty) {
            final decoded = json.decode(value);
            if (decoded is List) {
              return List<String>.from(decoded);
            }
          }
        } catch (e) {
          debugPrint('Error parsing categories: $e');
        }
      }
    }
    return const [];
  }
}

@immutable
class _DialogStyles {
  final BoxDecoration backdropDecoration;
  final BoxDecoration dialogDecoration;
  final BoxDecoration sectionDecoration;
  final BoxDecoration itemDecoration;
  final BoxDecoration badgeDecoration;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle priceStyle;

  const _DialogStyles({
    required this.backdropDecoration,
    required this.dialogDecoration,
    required this.sectionDecoration,
    required this.itemDecoration,
    required this.badgeDecoration,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.labelStyle,
    required this.valueStyle,
    required this.priceStyle,
  });

  factory _DialogStyles.from(ThemeData theme, bool isSmallScreen) {
    return _DialogStyles(
      backdropDecoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        backgroundBlendMode: BlendMode.darken,
      ),
      dialogDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(20),
          bottom: isSmallScreen ? Radius.zero : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      sectionDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      itemDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      badgeDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      subtitleStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      valueStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
      priceStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
        letterSpacing: 0.1,
      ) ?? const TextStyle(),
    );
  }
}

class WooOrderDetailsDialog extends HookConsumerWidget {
  final Map<String, dynamic> order;
  final bool isOpen;
  final Function(bool) onOpenChange;

  const WooOrderDetailsDialog({
    super.key,
    required this.order,
    required this.isOpen,
    required this.onOpenChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final statusColor = WooOrderUtils.statusColors[order['status']?.toLowerCase()] ?? Colors.grey;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final styles = useMemoized(() => _DialogStyles.from(theme, isSmallScreen), [theme, isSmallScreen]);

    // Memoize computed values
    final orderSubtotal = useMemoized(() {
      final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
      final shipping = double.tryParse(order['shipping_total']?.toString() ?? '0') ?? 0.0;
      final tax = double.tryParse(order['total_tax']?.toString() ?? '0') ?? 0.0;
      return total - shipping - tax;
    }, [order['total'], order['shipping_total'], order['total_tax']]);

    // Animation controller for dialog entry
    final animationController = useAnimationController(
      duration: WooOrderUtils.animationDuration,
    );

    // Slide animation
    final slideAnimation = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      )),
      [animationController],
    );

    // Fade animation
    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      )),
      [animationController],
    );

    // Start animation when dialog opens
    useEffect(() {
      animationController.forward();
      return null;
    }, const []);

    // Handle back gesture
    final handleDismiss = useCallback(() async {
      await animationController.reverse();
      onOpenChange(false);
    }, const []);

    return RepaintBoundary(
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            handleDismiss();
          }
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Backdrop
              AnimatedBuilder(
                animation: fadeAnimation,
                builder: (context, child) => GestureDetector(
                  onTap: handleDismiss,
                  child: Container(
                    decoration: styles.backdropDecoration.copyWith(
                      color: Colors.black.withOpacity(0.5 * fadeAnimation.value),
                    ),
                  ),
                ),
              ),

              // Dialog Content
              Positioned.fill(
                child: SlideTransition(
                  position: slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Main Content
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 0 : 16,
                            ),
                            decoration: styles.dialogDecoration,
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(20),
                                bottom: isSmallScreen ? Radius.zero : const Radius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  // Header
                                  RepaintBoundary(
                                    child: _OptimizedHeader(
                                      order: order,
                                      statusColor: statusColor,
                                      onClose: handleDismiss,
                                      styles: styles,
                                    ),
                                  ),

                                  // Scrollable Content
                                  Expanded(
                                    child: CustomScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      slivers: [
                                        SliverPadding(
                                          padding: const EdgeInsets.all(16),
                                          sliver: SliverList(
                                            delegate: SliverChildListDelegate([
                                              RepaintBoundary(
                                                child: _OptimizedOrderProducts(
                                                  order: order,
                                                  styles: styles,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              RepaintBoundary(
                                                child: _OptimizedCustomerInfo(
                                                  order: order,
                                                  styles: styles,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              RepaintBoundary(
                                                child: _OptimizedOrderSummary(
                                                  order: order,
                                                  orderSubtotal: orderSubtotal,
                                                  styles: styles,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              RepaintBoundary(
                                                child: _OptimizedPaymentMethod(
                                                  order: order,
                                                  styles: styles,
                                                ),
                                              ),
                                              if (order['customer_note']?.isNotEmpty == true) ...[
                                                const SizedBox(height: 16),
                                                RepaintBoundary(
                                                  child: _OptimizedCustomerNote(
                                                    note: order['customer_note']!,
                                                    styles: styles,
                                                  ),
                                                ),
                                              ],
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _OptimizedHeader extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final VoidCallback onClose;
  final _DialogStyles styles;

  const _OptimizedHeader({
    required this.order,
    required this.statusColor,
    required this.onClose,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = WooOrderUtils.formatDate(order['date_created'] ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton.filled(
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.box,
                            size: 14,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${order['number']}',
                          style: styles.titleStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: styles.subtitleStyle,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: styles.badgeDecoration.copyWith(
                            color: statusColor.withOpacity(0.1),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            (order['status'] ?? '').toUpperCase(),
                            style: styles.labelStyle.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@immutable
class _OptimizedOrderProducts extends StatelessWidget {
  final Map<String, dynamic> order;
  final _DialogStyles styles;

  const _OptimizedOrderProducts({
    required this.order,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = (order['line_items'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.box,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Order Products',
              style: styles.titleStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _OptimizedOrderItem(
              item: item,
              currency: order['currency'] ?? '\$',
              styles: styles,
            );
          },
        ),
      ],
    );
  }
}

@immutable
class _OptimizedCustomerInfo extends StatelessWidget {
  final Map<String, dynamic> order;
  final _DialogStyles styles;

  const _OptimizedCustomerInfo({
    required this.order,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OptimizedAddressCard(
            title: 'Billing',
            icon: FontAwesomeIcons.locationDot,
            color: WooOrderUtils.sectionColors['billing']!,
            address: order['billing'] ?? {},
            styles: styles,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OptimizedAddressCard(
            title: 'Shipping',
            icon: FontAwesomeIcons.truck,
            color: WooOrderUtils.sectionColors['shipping']!,
            address: order['shipping'] ?? {},
            styles: styles,
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedOrderSummary extends StatelessWidget {
  final Map<String, dynamic> order;
  final double orderSubtotal;
  final _DialogStyles styles;

  const _OptimizedOrderSummary({
    required this.order,
    required this.orderSubtotal,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final color = WooOrderUtils.sectionColors['summary']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.creditCard,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Order Summary',
              style: styles.titleStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: styles.sectionDecoration.copyWith(
            color: color.withOpacity(0.05),
          ),
          child: Column(
            children: [
              _OptimizedSummaryRow(
                label: 'Subtotal',
                value: '${order['currency']} ${orderSubtotal.toStringAsFixed(2)}',
                styles: styles,
              ),
              _OptimizedSummaryRow(
                label: 'Shipping',
                value: '${order['currency']} ${double.tryParse(order['shipping_total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                styles: styles,
              ),
              _OptimizedSummaryRow(
                label: 'Tax',
                value: '${order['currency']} ${double.tryParse(order['total_tax']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                styles: styles,
              ),
              if ((double.tryParse(order['discount_total']?.toString() ?? '0') ?? 0) > 0)
                _OptimizedSummaryRow(
                  label: 'Discount',
                  value: '-${order['currency']} ${double.tryParse(order['discount_total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                  isDiscount: true,
                  styles: styles,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              _OptimizedSummaryRow(
                label: 'Total',
                value: '${order['currency']} ${double.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                isTotal: true,
                styles: styles,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedPaymentMethod extends StatelessWidget {
  final Map<String, dynamic> order;
  final _DialogStyles styles;

  const _OptimizedPaymentMethod({
    required this.order,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final color = WooOrderUtils.sectionColors['payment']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.wallet,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Payment Method',
              style: styles.titleStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: styles.sectionDecoration.copyWith(
            color: color.withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Payment Method:',
                    style: styles.labelStyle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['payment_method_title'] ?? '',
                      style: styles.valueStyle,
                    ),
                  ),
                ],
              ),
              if (order['transaction_id']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Transaction ID:',
                      style: styles.labelStyle,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['transaction_id']!,
                        style: styles.valueStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedCustomerNote extends StatelessWidget {
  final String note;
  final _DialogStyles styles;

  const _OptimizedCustomerNote({
    required this.note,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final color = WooOrderUtils.sectionColors['note']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.noteSticky,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Customer Note',
              style: styles.titleStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: styles.sectionDecoration.copyWith(
            color: color.withOpacity(0.05),
          ),
          child: Text(
            note,
            style: styles.valueStyle,
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedOrderItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final String currency;
  final _DialogStyles styles;

  const _OptimizedOrderItem({
    required this.item,
    required this.currency,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemTotal = double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    final itemUnitPrice = quantity > 0 ? itemTotal / quantity : 0.0;

    final metaData = item['meta_data'] as List?;
    final variants = WooOrderUtils.getVariants(metaData);
    final customization = WooOrderUtils.getCustomization(metaData);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: styles.itemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: styles.titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${item['sku'] ?? 'N/A'} • Qty: ${item['quantity']}',
                      style: styles.subtitleStyle,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${itemTotal.toStringAsFixed(2)}',
                    style: styles.priceStyle,
                  ),
                  if (quantity > 1)
                    Text(
                      '$currency ${itemUnitPrice.toStringAsFixed(2)} each',
                      style: styles.subtitleStyle,
                    ),
                ],
              ),
            ],
          ),
          if (variants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: variants.map((variant) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${variant['label']}: ${variant['value']}',
                  style: styles.labelStyle.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )).toList(),
            ),
          ],
          if (customization.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customization:',
                    style: styles.labelStyle.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...customization.map((field) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${field['label']}:',
                            style: styles.labelStyle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            field['value'] ?? '',
                            style: styles.valueStyle,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

@immutable
class _OptimizedAddressCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> address;
  final _DialogStyles styles;

  const _OptimizedAddressCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.address,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: styles.titleStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: styles.sectionDecoration.copyWith(
            color: color.withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${address['first_name']} ${address['last_name']}',
                style: styles.valueStyle,
              ),
              if (address['company']?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  address['company'],
                  style: styles.valueStyle,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                address['address_1'] ?? '',
                style: styles.valueStyle,
              ),
              if (address['address_2']?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  address['address_2'],
                  style: styles.valueStyle,
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${address['city']}, ${address['state']} ${address['postcode']}',
                style: styles.valueStyle,
              ),
              const SizedBox(height: 2),
              Text(
                address['country'] ?? '',
                style: styles.valueStyle,
              ),
              if (address['email']?.isNotEmpty == true || address['phone']?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                if (address['email']?.isNotEmpty == true)
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address['email'],
                          style: styles.valueStyle.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (address['phone']?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address['phone'],
                        style: styles.valueStyle.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

@immutable
class _OptimizedSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isDiscount;
  final _DialogStyles styles;

  const _OptimizedSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDiscount 
      ? Colors.green 
      : isTotal 
        ? theme.colorScheme.primary
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? styles.titleStyle
                : styles.labelStyle.copyWith(color: textColor),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: isTotal
                ? styles.priceStyle
                : styles.valueStyle.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
} 