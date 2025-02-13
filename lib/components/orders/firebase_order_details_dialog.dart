// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../models/firebase_order.dart';
import 'order_tracking_dialog.dart';
import 'order_details_widgets.dart';

class FirebaseOrderDetailsDialog extends HookConsumerWidget {
  final FirebaseOrder order;
  final bool isOpen;
  final Function(bool) onOpenChange;

  const FirebaseOrderDetailsDialog({
    super.key,
    required this.order,
    required this.isOpen,
    required this.onOpenChange,
  });

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateStr;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cod':
        return Colors.orange;
      case 'prepaid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final statusColor = getStatusColor(order.status);
    final orderStatusColor = getOrderStatusColor(order.orderstatus);
    final isTrackingOpen = useState(false);
    final scrollController = useScrollController();
    final dragStartDetails = useState<DragStartDetails?>(null);

    if (isTrackingOpen.value && order.trackingId != null) {
      return OrderTrackingDialog(
        trackingId: order.trackingId!,
        isOpen: isTrackingOpen.value,
        onOpenChange: (value) => isTrackingOpen.value = value,
      );
    }

    return GestureDetector(
      onVerticalDragStart: (details) {
        dragStartDetails.value = details;
      },
      onVerticalDragUpdate: (details) {
        if (dragStartDetails.value != null) {
          final delta = details.globalPosition.dy - dragStartDetails.value!.globalPosition.dy;
          if (delta > 100) {
            // Swipe down to close
            HapticFeedback.mediumImpact();
            onOpenChange(false);
          }
        }
      },
      onVerticalDragEnd: (_) {
        dragStartDetails.value = null;
      },
      child: Material(
        color: theme.colorScheme.background,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onOpenChange(false);
                            },
                            icon: const Icon(Icons.arrow_back, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),
                        // Title and Customer Info
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.1),
                                    theme.colorScheme.primary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.boxOpen,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#${order.orderId}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.user,
                                    size: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.customerName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.calendar,
                                    size: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatDate(order.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 40), // For balance
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge(
                          text: order.status,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          text: order.orderstatus,
                          color: orderStatusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    physics: const BouncingScrollPhysics(),
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Products
                        DetailCard(
                          title: 'Order Items',
                          icon: FontAwesomeIcons.cartShopping,
                          trailing: '${order.products.length} items',
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.products.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) => _buildProductItem(
                              context,
                              order.products[index],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Customer Details
                        DetailCard(
                          title: 'Customer Details',
                          icon: FontAwesomeIcons.addressCard,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                DetailRow(
                                  label: 'Name',
                                  value: order.customerName,
                                  icon: FontAwesomeIcons.user,
                                ),
                                if (order.phone != null)
                                  DetailRow(
                                    label: 'Phone',
                                    value: order.phone!,
                                    icon: FontAwesomeIcons.phone,
                                    isPhone: true,
                                  ),
                                if (order.email != null)
                                  DetailRow(
                                    label: 'Email',
                                    value: order.email!,
                                    icon: FontAwesomeIcons.envelope,
                                  ),
                                if (order.address != null)
                                  DetailRow(
                                    label: 'Address',
                                    value: order.address!,
                                    icon: FontAwesomeIcons.locationDot,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        if (order.designUrl != null) ...[
                          const SizedBox(height: 16),
                          DetailCard(
                            title: 'Design File',
                            icon: FontAwesomeIcons.fileArrowDown,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Download design file',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                  CustomActionChip(
                                    text: 'Download',
                                    icon: FontAwesomeIcons.download,
                                    onTap: () async {
                                      final url = Uri.parse(order.designUrl!);
                                      if (await url_launcher.canLaunchUrl(url)) {
                                        await url_launcher.launchUrl(url);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (order.trackingId != null) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: CustomActionChip(
                              text: 'Track Order',
                              icon: FontAwesomeIcons.locationDot,
                              onTap: () => isTrackingOpen.value = true,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
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

  Widget _buildProductItem(BuildContext context, dynamic product) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.image.isNotEmpty)
            SizedBox(
              width: 48,
              height: 48,
              child: ProductImage(imageUrl: product.image),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ProductChip(
                      text: 'SKU: ${product.sku}',
                      icon: FontAwesomeIcons.barcode,
                    ),
                    ProductChip(
                      text: 'Qty: ${product.qty}',
                      icon: FontAwesomeIcons.cubes,
                    ),
                    ProductChip(
                      text: '₹${product.salePrice}',
                      icon: FontAwesomeIcons.tag,
                    ),
                    if (product.colour.isNotEmpty)
                      ProductChip(
                        text: 'Color: ${product.colour}',
                        icon: FontAwesomeIcons.palette,
                      ),
                    if (product.size.isNotEmpty)
                      ProductChip(
                        text: 'Size: ${product.size}',
                        icon: FontAwesomeIcons.ruler,
                      ),
                  ],
                ),
                if (product.productPageUrl.isNotEmpty || product.downloaddesign != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.productPageUrl.isNotEmpty)
                        CustomActionChip(
                          text: 'View Product',
                          icon: FontAwesomeIcons.link,
                          onTap: () async {
                            final url = Uri.parse(product.productPageUrl);
                            if (await url_launcher.canLaunchUrl(url)) {
                              await url_launcher.launchUrl(url);
                            }
                          },
                        ),
                      if (product.downloaddesign != null)
                        CustomActionChip(
                          text: 'Download Design',
                          icon: FontAwesomeIcons.download,
                          onTap: () async {
                            final url = Uri.parse(product.downloaddesign!);
                            if (await url_launcher.canLaunchUrl(url)) {
                              await url_launcher.launchUrl(url);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 