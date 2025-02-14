// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/firebase_order.dart';
import '../orders/order_tracking_dialog.dart';

// Utility class for Firebase Order Dialog
@immutable
class FirebaseOrderUtils {
  const FirebaseOrderUtils._();

  static const Duration animationDuration = Duration(milliseconds: 200);
  
  // Modern, minimalistic color palette
  static const Map<String, Color> statusColors = {
    'pending': Color(0xFFFFA726),    // Soft Orange
    'processing': Color(0xFF42A5F5), // Soft Blue
    'completed': Color(0xFF66BB6A),  // Soft Green
    'cancelled': Color(0xFFEF5350),  // Soft Red
    'refunded': Color(0xFF9575CD),   // Soft Purple
    'failed': Color(0xFFE57373),     // Light Red
  };

  static const Map<String, Color> sectionColors = {
    'billing': Color(0xFFEC407A),    // Soft Pink
    'shipping': Color(0xFF5C6BC0),   // Soft Indigo
    'payment': Color(0xFF26A69A),    // Soft Teal
    'summary': Color(0xFFFFB74D),    // Light Orange
    'note': Color(0xFF42A5F5),       // Soft Blue
  };

  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateStr;
    }
  }

  static Color getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? const Color(0xFF9E9E9E);
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
}

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final statusColor = FirebaseOrderUtils.getStatusColor(order.status);
    final orderStatusColor = FirebaseOrderUtils.getOrderStatusColor(order.orderstatus);
    final isTrackingOpen = useState(false);

    final animationController = useAnimationController(
      duration: FirebaseOrderUtils.animationDuration,
    );

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

    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      )),
      [animationController],
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, const []);

    if (isTrackingOpen.value && order.trackingId != null) {
      return OrderTrackingDialog(
        trackingId: order.trackingId!,
        isOpen: isTrackingOpen.value,
        onOpenChange: (value) => isTrackingOpen.value = value,
      );
    }

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
            // Gradient Background
            AnimatedBuilder(
              animation: fadeAnimation,
              builder: (context, _) => GestureDetector(
                onTap: handleDismiss,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1 * fadeAnimation.value),
                        theme.colorScheme.secondary.withOpacity(0.12 * fadeAnimation.value),
                        theme.colorScheme.tertiary.withOpacity(0.1 * fadeAnimation.value),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10 * fadeAnimation.value,
                      sigmaY: 10 * fadeAnimation.value,
                    ),
                    child: Container(
                      color: theme.colorScheme.scrim.withOpacity(0.32 * fadeAnimation.value),
                    ),
                  ),
                ),
              ),
            ),

            // Dialog Content
            SlideTransition(
              position: slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    const _DragHandle(),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.9),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Column(
                              children: [
                                _OrderHeader(
                                  order: order,
                                  statusColor: statusColor,
                                  orderStatusColor: orderStatusColor,
                                  onClose: handleDismiss,
                                ),
                                Expanded(
                                  child: _OrderContent(
                                    order: order,
                                    onTrackOrder: () => isTrackingOpen.value = true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final FirebaseOrder order;
  final Color statusColor;
  final Color orderStatusColor;
  final VoidCallback onClose;

  const _OrderHeader({
    required this.order,
    required this.statusColor,
    required this.orderStatusColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.8),
                theme.colorScheme.surface.withOpacity(0.7),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: onClose,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer.withOpacity(0.7),
                          theme.colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
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
                          '#${order.orderId}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.customerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      FirebaseOrderUtils.formatDate(order.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(theme, order.status, statusColor),
                  const SizedBox(width: 8),
                  _buildStatusBadge(theme, order.orderstatus, orderStatusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String text, Color color) {
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

class _OrderContent extends StatelessWidget {
  final FirebaseOrder order;
  final VoidCallback onTrackOrder;

  const _OrderContent({
    required this.order,
    required this.onTrackOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme: theme,
            title: 'Order Items',
            icon: Icons.shopping_cart_outlined,
            trailing: '${order.products.length} items',
            child: _buildOrderProducts(theme),
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme: theme,
            title: 'Customer Details',
            icon: Icons.person_outline,
            child: _buildCustomerDetails(theme),
          ),
          if (order.designUrl != null) ...[
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: 'Design File',
              icon: Icons.file_download_outlined,
              child: _buildDesignFile(theme),
            ),
          ],
          if (order.trackingId != null) ...[
            const SizedBox(height: 24),
            _buildTrackOrderButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    String? trailing,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.8),
                theme.colorScheme.surface.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
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
                        icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (trailing != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.15),
                              theme.colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          trailing,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withOpacity(0.05),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderProducts(ThemeData theme) {
    return Column(
      children: [
        for (var i = 0; i < order.products.length; i++) ...[
          _ProductItem(product: order.products[i]),
          if (i < order.products.length - 1)
            const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildCustomerDetails(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DetailRow(
            label: 'Name',
            value: order.customerName,
            icon: Icons.person_outline,
          ),
          if (order.phone != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Phone',
              value: order.phone!,
              icon: Icons.phone_outlined,
              isPhone: true,
            ),
          ],
          if (order.email != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Email',
              value: order.email!,
              icon: Icons.email_outlined,
            ),
          ],
          if (order.address != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Address',
              value: order.address!,
              icon: Icons.location_on_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignFile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Download design file',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              final url = Uri.parse(order.designUrl!);
              if (await url_launcher.canLaunchUrl(url)) {
                await url_launcher.launchUrl(url);
              }
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackOrderButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onTrackOrder,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.local_shipping_outlined, size: 20),
          label: Text(
            'Track Order',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final dynamic product;

  const _ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.image.isNotEmpty)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
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
                        size: 24,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.details,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildProductDetail(
                      theme,
                      'SKU',
                      product.sku,
                      Icons.qr_code_outlined,
                    ),
                    _buildProductDetail(
                      theme,
                      'Qty',
                      product.qty.toString(),
                      Icons.inventory_2_outlined,
                    ),
                    _buildProductDetail(
                      theme,
                      'Price',
                      '₹${product.salePrice}',
                      Icons.payments_outlined,
                      isHighlighted: true,
                    ),
                  ],
                ),
                if (product.colour.isNotEmpty || product.size.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (product.colour.isNotEmpty)
                        _buildProductDetail(
                          theme,
                          'Color',
                          product.colour,
                          Icons.palette_outlined,
                        ),
                      if (product.size.isNotEmpty)
                        _buildProductDetail(
                          theme,
                          'Size',
                          product.size,
                          Icons.straighten,
                        ),
                    ],
                  ),
                ],
                if (product.productPageUrl.isNotEmpty || product.downloaddesign != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (product.productPageUrl.isNotEmpty)
                        _buildActionButton(
                          theme,
                          'View Product',
                          Icons.visibility_outlined,
                          () async {
                            final url = Uri.parse(product.productPageUrl);
                            if (await url_launcher.canLaunchUrl(url)) {
                              await url_launcher.launchUrl(url);
                            }
                          },
                        ),
                      if (product.downloaddesign != null)
                        _buildActionButton(
                          theme,
                          'Download Design',
                          Icons.download_outlined,
                          () async {
                            final url = Uri.parse(product.downloaddesign!);
                            if (await url_launcher.canLaunchUrl(url)) {
                              await url_launcher.launchUrl(url);
                            }
                          },
                          isPrimary: true,
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

  Widget _buildProductDetail(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
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

  Widget _buildActionButton(
    ThemeData theme,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.8),
      ),
      label: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPhone;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondaryContainer.withOpacity(0.4),
                theme.colorScheme.secondaryContainer.withOpacity(0.2),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              if (isPhone)
                InkWell(
                  onTap: () => url_launcher.launchUrl(Uri.parse('tel:$value')),
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 