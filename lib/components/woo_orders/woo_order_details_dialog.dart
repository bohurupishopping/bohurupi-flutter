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
  
  // Memoized color mappings for better performance
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

  // Optimized utility methods
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

    return GestureDetector(
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
              animation: animationController,
              builder: (context, child) => GestureDetector(
                onTap: handleDismiss,
                child: Container(
                  color: Colors.black.withOpacity(0.5 * fadeAnimation.value),
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
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.vertical(
                              top: const Radius.circular(20),
                              bottom: isSmallScreen ? Radius.zero : const Radius.circular(20),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: const Radius.circular(20),
                              bottom: isSmallScreen ? Radius.zero : const Radius.circular(20),
                            ),
                            child: Column(
                              children: [
                                // Header
                                _DialogHeader(
                                  order: order,
                                  statusColor: statusColor,
                                  onClose: handleDismiss,
                                ),

                                // Scrollable Content
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildOrderProducts(theme, order),
                                        const SizedBox(height: 16),
                                        _buildCustomerInformation(theme, order),
                                        const SizedBox(height: 16),
                                        _buildOrderSummary(theme, order, orderSubtotal),
                                        const SizedBox(height: 16),
                                        _buildPaymentMethod(theme, order),
                                        if (order['customer_note']?.isNotEmpty == true) ...[
                                          const SizedBox(height: 16),
                                          _buildCustomerNote(theme, order['customer_note']!),
                                        ],
                                      ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProducts(ThemeData theme, Map<String, dynamic> order) {
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

  Widget _buildCustomerInformation(ThemeData theme, Map<String, dynamic> order) {
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

  Widget _buildOrderSummary(ThemeData theme, Map<String, dynamic> order, double orderSubtotal) {
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

  Widget _buildPaymentMethod(ThemeData theme, Map<String, dynamic> order) {
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

  Widget _buildCustomerNote(ThemeData theme, String note) {
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
              style: const TextStyle(
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
}

// Rest of the widget implementations remain the same, just update their constructors to use const where possible
// and add performance optimizations like mainAxisSize: MainAxisSize.min where appropriate

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
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
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.box,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${order['number']}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                          DateFormat('MMM d, y h:mm a').format(
                            DateTime.parse(order['date_created'] ?? ''),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
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

// Keep the rest of the widget implementations but add const constructors and optimize their builds
// ... rest of the file remains the same ... 

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