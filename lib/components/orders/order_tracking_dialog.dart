import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../models/tracking_data.dart';
import '../../services/tracking_service.dart';

final trackingServiceProvider = Provider((ref) => TrackingService());

final trackingDataProvider = FutureProvider.family<TrackingData, String>(
  (ref, trackingId) async {
    final service = ref.read(trackingServiceProvider);
    return service.getTrackingInfo(trackingId);
  },
);

@immutable
class OrderTrackingDialog extends HookConsumerWidget {
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const double kHeaderHeight = 64;
  static const double _borderRadius = 28.0;

  final String trackingId;
  final bool isOpen;
  final Function(bool) onOpenChange;

  const OrderTrackingDialog({
    super.key,
    required this.trackingId,
    required this.isOpen,
    required this.onOpenChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final animationController = useAnimationController(
      duration: animationDuration,
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

    final handleDismiss = useCallback(() async {
      await animationController.reverse();
      onOpenChange(false);
    }, const []);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Scrim layer with optimized animation
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: fadeAnimation,
              builder: (context, _) => GestureDetector(
                onTap: handleDismiss,
                child: Container(
                  color: theme.colorScheme.scrim.withOpacity(0.32 * fadeAnimation.value),
                ),
              ),
            ),
          ),

          // Dialog content with optimized slide animation
          RepaintBoundary(
            child: SlideTransition(
              position: slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    const _DragHandle(),
                    Expanded(
                      child: RepaintBoundary(
                        child: _OptimizedDialogContainer(
                          child: _TrackingDialogContent(
                            trackingId: trackingId,
                            onClose: handleDismiss,
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
    );
  }
}

// New widget to optimize container decorations
@immutable
class _OptimizedDialogContainer extends StatelessWidget {
  final Widget child;

  const _OptimizedDialogContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(OrderTrackingDialog._borderRadius),
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 0.5,
        ),
        // Simplified shadow for better performance
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: child,
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
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _TrackingDialogContent extends HookConsumerWidget {
  final String trackingId;
  final VoidCallback onClose;

  const _TrackingDialogContent({
    required this.trackingId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trackingData = ref.watch(trackingDataProvider(trackingId));

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 500) onClose();
      },
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              RepaintBoundary(
                child: _buildHeader(theme),
              ),
              Expanded(
                child: trackingData.when(
                  data: (data) => _TrackingContent(
                    data: data,
                    onRefresh: () => ref.refresh(trackingDataProvider(trackingId).future),
                  ),
                  loading: () => const _LoadingIndicator(),
                  error: (error, _) => _ErrorView(
                    error: error,
                    onClose: onClose,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      height: OrderTrackingDialog.kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _HeaderButton(
              icon: FontAwesomeIcons.arrowLeft,
              onPressed: onClose,
            ),
          ),
          _TrackingIdBadge(trackingId: trackingId),
        ],
      ),
    );
  }
}

@immutable
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(32, 32),
      ),
    );
  }
}

@immutable
class _TrackingIdBadge extends StatelessWidget {
  final String trackingId;

  const _TrackingIdBadge({required this.trackingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          FaIcon(
            FontAwesomeIcons.truck,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Tracking #$trackingId',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

@immutable
class _TrackingContent extends StatelessWidget {
  final TrackingData data;
  final Future<void> Function() onRefresh;

  const _TrackingContent({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (data.shipmentData.isEmpty) {
      return const _EmptyState();
    }

    final shipment = data.shipmentData[0].shipment;
    final statusColor = _TrackingUtils.getStatusColor(shipment.status.status);

    return RepaintBoundary(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  RepaintBoundary(
                    child: _StatusCard(shipment: shipment, statusColor: statusColor),
                  ),
                  const SizedBox(height: 16),
                  if (shipment.estimatedDeliveryDate != null) ...[
                    RepaintBoundary(
                      child: _EstimatedDeliveryCard(shipment: shipment),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const RepaintBoundary(child: _TrackingHistoryHeader()),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: _TrackingHistory(shipment: shipment),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _TrackingUtils {
  const _TrackingUtils._();

  static Color getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('delivered')) return Colors.green;
    if (statusLower.contains('transit')) return Colors.blue;
    if (statusLower.contains('picked')) return Colors.purple;
    if (statusLower.contains('pending')) return Colors.amber;
    if (statusLower.contains('failed')) return Colors.red;
    return Colors.grey;
  }

  static IconData getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('delivered')) return FontAwesomeIcons.checkDouble;
    if (statusLower.contains('transit')) return FontAwesomeIcons.truck;
    if (statusLower.contains('picked')) return FontAwesomeIcons.boxArchive;
    if (statusLower.contains('pending')) return FontAwesomeIcons.magnifyingGlass;
    if (statusLower.contains('failed')) return FontAwesomeIcons.xmark;
    return FontAwesomeIcons.box;
  }
}

@immutable
class _StatusCard extends StatelessWidget {
  final Shipment shipment;
  final Color statusColor;

  const _StatusCard({
    required this.shipment,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: statusColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.9),
                            theme.colorScheme.surface.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: FaIcon(
                        _TrackingUtils.getStatusIcon(shipment.status.status),
                        size: 20,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipment.status.status,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          if (shipment.status.statusLocation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    shipment.status.statusLocation,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, y h:mm a').format(
                          DateTime.parse(shipment.status.statusDateTime),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
    );
  }
}

@immutable
class _EstimatedDeliveryCard extends StatelessWidget {
  final Shipment shipment;

  const _EstimatedDeliveryCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blueOpacity01 = Colors.blue.withOpacity(0.1);
    final blueOpacity02 = Colors.blue.withOpacity(0.2);
    final blueOpacity05 = Colors.blue.withOpacity(0.05);

    return Card(
      elevation: 0,
      color: blueOpacity05,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: blueOpacity02),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: blueOpacity01,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const FaIcon(
                FontAwesomeIcons.calendarCheck,
                size: 20,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(
                      DateTime.parse(shipment.estimatedDeliveryDate!),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _TrackingHistoryHeader extends StatelessWidget {
  const _TrackingHistoryHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FaIcon(
          FontAwesomeIcons.clockRotateLeft,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Tracking History',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

@immutable
class _TrackingHistory extends StatelessWidget {
  final Shipment shipment;

  const _TrackingHistory({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shipment.scans.length,
      itemBuilder: (context, index) {
        final scan = shipment.scans[index];
        final isFirst = index == 0;
        final isLast = index == shipment.scans.length - 1;
        final statusColor = _TrackingUtils.getStatusColor(scan.scanDetail.scan);

        return _TrackingHistoryItem(
          scan: scan,
          isFirst: isFirst,
          isLast: isLast,
          statusColor: statusColor,
        );
      },
    );
  }
}

@immutable
class _TrackingHistoryItem extends StatelessWidget {
  final dynamic scan;
  final bool isFirst;
  final bool isLast;
  final Color statusColor;

  const _TrackingHistoryItem({
    required this.scan,
    required this.isFirst,
    required this.isLast,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColorOpacity01 = statusColor.withOpacity(0.1);
    final statusColorOpacity02 = statusColor.withOpacity(0.2);
    final onSurfaceOpacity03 = theme.colorScheme.onSurface.withOpacity(0.3);
    final onSurfaceOpacity05 = theme.colorScheme.onSurface.withOpacity(0.5);
    final onSurfaceOpacity06 = theme.colorScheme.onSurface.withOpacity(0.6);
    final onSurfaceOpacity07 = theme.colorScheme.onSurface.withOpacity(0.7);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);
    final outlineOpacity02 = theme.colorScheme.outline.withOpacity(0.2);
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity05 = theme.colorScheme.primary.withOpacity(0.05);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isFirst ? statusColor : theme.colorScheme.surface,
                    border: Border.all(
                      color: isFirst ? statusColor : onSurfaceOpacity03,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: outlineOpacity02,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: outlineOpacity01,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColorOpacity01,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColorOpacity02,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              _TrackingUtils.getStatusIcon(scan.scanDetail.scan),
                              size: 10,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan.scanDetail.scan,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d, h:mm a').format(
                            DateTime.parse(scan.scanDetail.scanDateTime),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurfaceOpacity06,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  if (scan.scanDetail.scanLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: 10,
                          color: onSurfaceOpacity05,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scan.scanDetail.scanLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurfaceOpacity07,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (scan.scanDetail.instructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryOpacity05,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: primaryOpacity01,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: FaIcon(
                              FontAwesomeIcons.circleInfo,
                              size: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              scan.scanDetail.instructions,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryOpacity05 = theme.colorScheme.primary.withOpacity(0.5);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);
    final onSurfaceOpacity06 = theme.colorScheme.onSurface.withOpacity(0.6);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: outlineOpacity01,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: primaryOpacity05,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tracking Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tracking information available for this order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceOpacity06,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onClose;

  const _ErrorView({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorOpacity02 = theme.colorScheme.error.withOpacity(0.2);
    final errorOpacity05 = theme.colorScheme.error.withOpacity(0.05);
    final errorOpacity07 = theme.colorScheme.error.withOpacity(0.7);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorOpacity05,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: errorOpacity02,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Tracking Data',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: errorOpacity07,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onClose,
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 14),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 