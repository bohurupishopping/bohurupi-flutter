import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/firebase_order.dart';
import '../orders/firebase_order_details_dialog.dart';
import '../orders/order_tracking_dialog.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.getStatusColor,
    required this.getOrderStatusColor,
    required this.formatDate,
  });

  final FirebaseOrder order;
  final Color Function(String) getStatusColor;
  final Color Function(String) getOrderStatusColor;
  final String Function(String?) formatDate;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = widget.getStatusColor(widget.order.status);
    final orderStatusColor = widget.getOrderStatusColor(widget.order.orderstatus);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.05),
            ),
          ),
          elevation: _isPressed ? 0 : 1,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                useSafeArea: false,
                builder: (context) => FirebaseOrderDetailsDialog(
                  order: widget.order,
                  isOpen: true,
                  onOpenChange: (isOpen) {
                    if (!isOpen) Navigator.of(context).pop();
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _OrderHeader(
                  order: widget.order,
                  statusColor: statusColor,
                  orderStatusColor: orderStatusColor,
                  formatDate: widget.formatDate,
                ),
                _OrderProducts(products: widget.order.products),
                _OrderActions(
                  order: widget.order,
                  onViewDetails: () {
                    HapticFeedback.mediumImpact();
                    showDialog(
                      context: context,
                      useSafeArea: false,
                      builder: (context) => FirebaseOrderDetailsDialog(
                        order: widget.order,
                        isOpen: true,
                        onOpenChange: (isOpen) {
                          if (!isOpen) Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  onTrackOrder: widget.order.trackingId != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          showDialog(
                            context: context,
                            useSafeArea: false,
                            builder: (context) => OrderTrackingDialog(
                              trackingId: widget.order.trackingId!,
                              isOpen: true,
                              onOpenChange: (isOpen) {
                                if (!isOpen) Navigator.of(context).pop();
                              },
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({
    required this.order,
    required this.statusColor,
    required this.orderStatusColor,
    required this.formatDate,
  });

  final FirebaseOrder order;
  final Color statusColor;
  final Color orderStatusColor;
  final String Function(String?) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
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
                    Flexible(
                      child: Text(
                        '#${order.orderId}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      text: order.status,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    _StatusBadge(
                      text: order.orderstatus,
                      color: orderStatusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: FontAwesomeIcons.calendar,
                text: formatDate(order.createdAt),
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: FontAwesomeIcons.user,
                text: order.customerName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
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
            Flexible(
              child: Text(
                text.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProducts extends StatelessWidget {
  const _OrderProducts({
    required this.products,
  });

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (var product in products)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.05),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.image.isNotEmpty)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: _ProductImage(imageUrl: product.image),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
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
                            _ProductChip(
                              text: 'SKU: ${product.sku}',
                              icon: FontAwesomeIcons.barcode,
                            ),
                            _ProductChip(
                              text: 'Qty: ${product.qty}',
                              icon: FontAwesomeIcons.cubes,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.colorScheme.surface,
              child: Icon(
                Icons.image_not_supported,
                size: 24,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 10,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.onViewDetails,
    required this.onTrackOrder,
  });

  final FirebaseOrder order;
  final VoidCallback onViewDetails;
  final VoidCallback? onTrackOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              text: 'View Details',
              icon: FontAwesomeIcons.eye,
              onPressed: onViewDetails,
            ),
          ),
          if (onTrackOrder != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                text: 'Track Order',
                icon: FontAwesomeIcons.locationDot,
                onPressed: onTrackOrder!,
                isPrimary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Material(
          color: widget.isPrimary ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onPressed();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: widget.isPrimary
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    widget.icon,
                    size: 14,
                    color: widget.isPrimary
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: widget.isPrimary
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
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