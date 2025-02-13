import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/firebase_order.dart';
import '../orders/firebase_order_details_dialog.dart';
import '../orders/order_tracking_dialog.dart';

class OrderCard extends StatefulWidget {
  static const double _kSpacing = 12.0;
  static const double _kSmallSpacing = 8.0;
  static const double _kBorderRadius = 12.0;
  static const double _kIconSize = 16.0;
  static const double _kSmallIconSize = 14.0;

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

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
        child: Container(
          margin: const EdgeInsets.only(bottom: OrderCard._kSmallSpacing),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(OrderCard._kBorderRadius),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
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
              borderRadius: BorderRadius.circular(OrderCard._kBorderRadius),
              child: Column(
                children: [
                  _OrderHeader(
                    order: widget.order,
                    statusColor: statusColor,
                    orderStatusColor: orderStatusColor,
                    formatDate: widget.formatDate,
                    isSmallScreen: isSmallScreen,
                  ),
                  _OrderProducts(
                    products: widget.order.products,
                    isSmallScreen: isSmallScreen,
                  ),
                  _OrderActions(
                    order: widget.order,
                    isSmallScreen: isSmallScreen,
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
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final FirebaseOrder order;
  final Color statusColor;
  final Color orderStatusColor;
  final String Function(String?) formatDate;
  final bool isSmallScreen;

  const _OrderHeader({
    required this.order,
    required this.statusColor,
    required this.orderStatusColor,
    required this.formatDate,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? OrderCard._kSmallSpacing : OrderCard._kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OrderCard._kBorderRadius),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
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
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.boxOpen,
                        size: isSmallScreen ? OrderCard._kSmallIconSize : OrderCard._kIconSize,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
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
                      isSmallScreen: isSmallScreen,
                    ),
                    const SizedBox(width: 6),
                    _StatusBadge(
                      text: order.orderstatus,
                      color: orderStatusColor,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              _InfoChip(
                icon: FontAwesomeIcons.calendar,
                text: formatDate(order.createdAt),
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              _InfoChip(
                icon: FontAwesomeIcons.user,
                text: order.customerName,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isSmallScreen;

  const _StatusBadge({
    required this.text,
    required this.color,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 6,
          vertical: isSmallScreen ? 2 : 3,
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
                  fontSize: isSmallScreen ? 9 : 10,
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
  final IconData icon;
  final String text;
  final bool isSmallScreen;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: isSmallScreen ? 10 : 12,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProducts extends StatelessWidget {
  final List<dynamic> products;
  final bool isSmallScreen;

  const _OrderProducts({
    required this.products,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? OrderCard._kSmallSpacing : OrderCard._kSpacing),
      child: Column(
        children: [
          for (var product in products)
            Container(
              margin: EdgeInsets.only(
                bottom: isSmallScreen ? 6 : 8,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.image.isNotEmpty)
                    SizedBox(
                      width: isSmallScreen ? 40 : 48,
                      height: isSmallScreen ? 40 : 48,
                      child: _ProductImage(
                        imageUrl: product.image,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
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
                          spacing: isSmallScreen ? 4 : 6,
                          runSpacing: 4,
                          children: [
                            _ProductChip(
                              text: 'SKU: ${product.sku}',
                              icon: FontAwesomeIcons.barcode,
                              isSmallScreen: isSmallScreen,
                            ),
                            _ProductChip(
                              text: 'Qty: ${product.qty}',
                              icon: FontAwesomeIcons.cubes,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
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
  final String imageUrl;
  final bool isSmallScreen;

  const _ProductImage({
    required this.imageUrl,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(OrderCard._kBorderRadius / 2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.colorScheme.surfaceVariant,
              child: Icon(
                FontAwesomeIcons.image,
                size: isSmallScreen ? OrderCard._kSmallIconSize : OrderCard._kIconSize,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSmallScreen;

  const _ProductChip({
    required this.text,
    required this.icon,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: isSmallScreen ? 10 : 12,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isSmallScreen ? 9 : 10,
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
  final FirebaseOrder order;
  final VoidCallback onViewDetails;
  final VoidCallback? onTrackOrder;
  final bool isSmallScreen;

  const _OrderActions({
    required this.order,
    required this.onViewDetails,
    required this.onTrackOrder,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? OrderCard._kSmallSpacing : OrderCard._kSpacing,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(OrderCard._kBorderRadius),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
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
              isSmallScreen: isSmallScreen,
            ),
          ),
          if (onTrackOrder != null) ...[
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _ActionButton(
                text: 'Track Order',
                icon: FontAwesomeIcons.locationDot,
                onPressed: onTrackOrder!,
                isPrimary: true,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isSmallScreen;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    required this.isSmallScreen,
  });

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
          borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onPressed();
            },
            borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: widget.isSmallScreen ? 8 : 10,
              ),
              decoration: BoxDecoration(
                border: widget.isPrimary
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                borderRadius: BorderRadius.circular(OrderCard._kBorderRadius / 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    widget.icon,
                    size: widget.isSmallScreen ? OrderCard._kSmallIconSize : OrderCard._kIconSize,
                    color: widget.isPrimary
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  SizedBox(width: widget.isSmallScreen ? 6 : 8),
                  Text(
                    widget.text,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: widget.isPrimary
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: widget.isSmallScreen ? 12 : 14,
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