// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Constants and utilities for WooOrder
class WooOrderUtils {
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  static final Map<String, Color> statusColors = {
    'pending': Colors.amber,
    'processing': Colors.blue,
    'on-hold': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'refunded': Colors.purple,
    'failed': Colors.red.shade700,
  };

  static final Map<String, Color> sectionColors = {
    'billing': Colors.pink,
    'shipping': Colors.indigo,
    'payment': Colors.teal,
    'summary': Colors.amber,
    'note': Colors.blue,
  };

  static Map<String, String>? getProductUrls(List<dynamic>? metaData) {
    if (metaData == null) return null;

    String? productUrl;
    String? downloadUrl;

    for (final meta in metaData) {
      final key = meta['key']?.toString() ?? '';
      if (key == '_product_url' || key == 'product_url') {
        productUrl = meta['value']?.toString();
      } else if (key == '_download_url' || key == 'download_url') {
        downloadUrl = meta['value']?.toString();
      }
    }

    if (productUrl == null && downloadUrl == null) return null;

    return {
      if (productUrl != null) 'product_url': productUrl,
      if (downloadUrl != null) 'download_url': downloadUrl,
    };
  }

  static List<Map<String, String>> getVariants(List<dynamic>? metaData) {
    if (metaData == null) return [];

    final variants = <Map<String, String>>[];
    
    for (final meta in metaData) {
      final key = meta['key']?.toString().toLowerCase() ?? '';
      final value = meta['value']?.toString() ?? '';
      
      if (key.contains('size') || key == 'pa_size') {
        variants.add({
          'type': 'size',
          'label': 'Size',
          'value': value,
        });
      } else if (key.contains('color') || key.contains('colour') || key == 'pa_color') {
        variants.add({
          'type': 'color',
          'label': 'Color',
          'value': value,
        });
      }
    }

    return variants;
  }

  static List<Map<String, String>> getCustomization(List<dynamic>? metaData) {
    if (metaData == null) return [];

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
        'label': (meta['display_key']?.toString() ?? meta['key']?.toString() ?? '').replaceAll('_', ' '),
        'value': meta['display_value']?.toString() ?? meta['value']?.toString() ?? '',
      })
      .toList();
  }

  static List<String> getCategories(List<dynamic>? metaData) {
    if (metaData == null) return [];

    for (final meta in metaData) {
      if (meta['key'] == '_product_categories' || meta['key'] == 'product_categories') {
        try {
          final value = meta['value']?.toString() ?? '';
          if (value.isNotEmpty) {
            final decoded = json.decode(value);
            if (decoded is List) {
              return decoded.map((c) => c.toString()).toList();
            }
          }
        } catch (e) {
          debugPrint('Error parsing categories: $e');
        }
      }
    }

    return [];
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

  Color getStatusColor(String status) => 
    WooOrderUtils.statusColors[status.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    // Memoize computed values
    final statusColor = useMemoized(
      () => getStatusColor(order['status'] ?? ''),
      [order['status']],
    );

    final orderSubtotal = useMemoized(() {
      final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
      final shipping = double.tryParse(order['shipping_total']?.toString() ?? '0') ?? 0.0;
      final tax = double.tryParse(order['total_tax']?.toString() ?? '0') ?? 0.0;
      return total - shipping - tax;
    }, [order['total'], order['shipping_total'], order['total_tax']]);

    return Material(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Stack(
          children: [
            // Background gradient - using const for better performance
            const _BackgroundGradient(),

            // Main content
            Column(
              children: [
                // Dialog Header - extracted to a separate widget for better performance
                _DialogHeader(
                  order: order,
                  statusColor: statusColor,
                  onClose: () => onOpenChange(false),
                ),

                // Dialog Content - using Expanded to avoid layout issues
                Expanded(
                  child: _DialogContent(
                    order: order,
                    orderSubtotal: orderSubtotal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted background gradient widget with const constructor
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.background.withOpacity(0.8),
              theme.colorScheme.background.withOpacity(0.9),
            ],
          ),
        ),
      ),
    );
  }
}

// Extracted dialog header widget
class _DialogHeader extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.order,
    required this.statusColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _HeaderContent(
        order: order,
        statusColor: statusColor,
        onClose: onClose,
      ),
    );
  }
}

// Extracted header content for better organization
class _HeaderContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final VoidCallback onClose;

  const _HeaderContent({
    required this.order,
    required this.statusColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: const CircleBorder(),
            ),
          ),
        ),
        // Title and Status
        Column(
          children: [
            _OrderTitle(order: order),
            const SizedBox(height: 6),
            _OrderMetadata(
              order: order,
              statusColor: statusColor,
            ),
          ],
        ),
      ],
    );
  }
}

// Extracted dialog content widget
class _DialogContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final double orderSubtotal;

  const _DialogContent({
    required this.order,
    required this.orderSubtotal,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Products
          _OrderProducts(order: order),
          const SizedBox(height: 16),

          // Customer Information
          _CustomerInformation(order: order),
          const SizedBox(height: 16),

          // Order Summary
          _OrderSummary(
            order: order,
            orderSubtotal: orderSubtotal,
          ),
          const SizedBox(height: 16),

          // Payment Method
          _PaymentMethod(order: order),

          // Customer Note
          if (order['customer_note']?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _CustomerNote(note: order['customer_note']!),
          ],
        ],
      ),
    );
  }
}

Widget _buildSection({
  required String title,
  required IconData icon,
  required Color color,
  required Widget content,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          FaIcon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      content,
    ],
  );
}

class _OrderItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final String currency;

  const _OrderItem({
    required this.item,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemTotal = double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    final itemUnitPrice = quantity > 0 ? itemTotal / quantity : 0.0;

    // Extract product details using WooOrderUtils
    final metaData = item['meta_data'] as List?;
    final urls = WooOrderUtils.getProductUrls(metaData);
    final variants = WooOrderUtils.getVariants(metaData);
    final customization = WooOrderUtils.getCustomization(metaData);
    final categories = WooOrderUtils.getCategories(metaData);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.05),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${item['sku'] ?? 'N/A'} • Qty: ${item['quantity']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${itemTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (quantity > 1)
                    Text(
                      '$currency ${itemUnitPrice.toStringAsFixed(2)} each',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Variants
          if (variants.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: variants.map((variant) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${variant['label']}: ${variant['value']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )).toList(),
            ),
          ],

          // Customization
          if (customization.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customization:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...customization.map((field) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${field['label']}:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            field['value'] ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],

          // Categories
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: categories.map((category) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              )).toList(),
            ),
          ],

          // Product URLs
          if (urls != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (urls['product_url'] != null)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement URL launcher
                      debugPrint('Launch product URL: ${urls['product_url']}');
                    },
                    icon: const Icon(Icons.link, size: 14),
                    label: const Text('View Product'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      textStyle: theme.textTheme.bodySmall,
                    ),
                  ),
                if (urls['download_url'] != null)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement URL launcher
                      debugPrint('Launch download URL: ${urls['download_url']}');
                    },
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      textStyle: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final Color color;

  const _AddressCard({
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${address['first_name']} ${address['last_name']}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (address['company']?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text(
              address['company'],
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            address['address_1'] ?? '',
            style: theme.textTheme.bodySmall,
          ),
          if (address['address_2']?.isNotEmpty == true) ...[
            const SizedBox(height: 1),
            Text(
              address['address_2'],
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 1),
          Text(
            '${address['city']}, ${address['state']} ${address['postcode']}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 1),
          Text(
            address['country'] ?? '',
            style: theme.textTheme.bodySmall,
          ),
          if (address['email']?.isNotEmpty == true || address['phone']?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            if (address['email']?.isNotEmpty == true)
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address['email'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (address['phone']?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    address['phone'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: isTotal
                  ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.bodySmall?.copyWith(
                      color: isDiscount ? Colors.green : null,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDiscount ? Colors.green : null,
                  ),
          ),
        ],
      ),
    );
  }
}

// Order Title Widget
class _OrderTitle extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderTitle({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FaIcon(
            FontAwesomeIcons.box,
            size: 14,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Order #${order['number']}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Order Metadata Widget
class _OrderMetadata extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;

  const _OrderMetadata({
    required this.order,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM d, y h:mm a').format(
                DateTime.parse(order['date_created'] ?? ''),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            (order['status'] ?? '').toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Order Products Widget
class _OrderProducts extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderProducts({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      title: 'Order Products',
      icon: FontAwesomeIcons.box,
      color: theme.colorScheme.primary,
      content: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: (order['line_items'] as List?)?.length ?? 0,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = (order['line_items'] as List)[index];
          return _OrderItem(
            item: item,
            currency: order['currency'] ?? '\$',
          );
        },
      ),
    );
  }
}

// Customer Information Widget
class _CustomerInformation extends StatelessWidget {
  final Map<String, dynamic> order;

  const _CustomerInformation({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSection(
            title: 'Billing',
            icon: FontAwesomeIcons.locationDot,
            color: WooOrderUtils.sectionColors['billing']!,
            content: _AddressCard(
              address: order['billing'] ?? {},
              color: WooOrderUtils.sectionColors['billing']!,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSection(
            title: 'Shipping',
            icon: FontAwesomeIcons.truck,
            color: WooOrderUtils.sectionColors['shipping']!,
            content: _AddressCard(
              address: order['shipping'] ?? {},
              color: WooOrderUtils.sectionColors['shipping']!,
            ),
          ),
        ),
      ],
    );
  }
}

// Order Summary Widget
class _OrderSummary extends StatelessWidget {
  final Map<String, dynamic> order;
  final double orderSubtotal;

  const _OrderSummary({
    required this.order,
    required this.orderSubtotal,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: 'Order Summary',
      icon: FontAwesomeIcons.creditCard,
      color: WooOrderUtils.sectionColors['summary']!,
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WooOrderUtils.sectionColors['summary']!.withOpacity(0.05),
              WooOrderUtils.sectionColors['summary']!.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WooOrderUtils.sectionColors['summary']!.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: '${order['currency']} ${orderSubtotal.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              label: 'Shipping',
              value: '${order['currency']} ${double.tryParse(order['shipping_total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
            ),
            _SummaryRow(
              label: 'Tax',
              value: '${order['currency']} ${double.tryParse(order['total_tax']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
            ),
            if ((double.tryParse(order['discount_total']?.toString() ?? '0') ?? 0) > 0)
              _SummaryRow(
                label: 'Discount',
                value: '-${order['currency']} ${double.tryParse(order['discount_total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                isDiscount: true,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            _SummaryRow(
              label: 'Total',
              value: '${order['currency']} ${double.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Method Widget
class _PaymentMethod extends StatelessWidget {
  final Map<String, dynamic> order;

  const _PaymentMethod({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      title: 'Payment Method',
      icon: FontAwesomeIcons.wallet,
      color: WooOrderUtils.sectionColors['payment']!,
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WooOrderUtils.sectionColors['payment']!.withOpacity(0.05),
              WooOrderUtils.sectionColors['payment']!.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WooOrderUtils.sectionColors['payment']!.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Payment Method:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['payment_method_title'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (order['transaction_id']?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Transaction ID:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['transaction_id']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Customer Note Widget
class _CustomerNote extends StatelessWidget {
  final String note;

  const _CustomerNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      title: 'Customer Note',
      icon: FontAwesomeIcons.noteSticky,
      color: WooOrderUtils.sectionColors['note']!,
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WooOrderUtils.sectionColors['note']!.withOpacity(0.05),
              WooOrderUtils.sectionColors['note']!.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WooOrderUtils.sectionColors['note']!.withOpacity(0.1),
          ),
        ),
        child: Text(
          note,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
} 