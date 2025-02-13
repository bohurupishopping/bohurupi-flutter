import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../models/tracking_data.dart';
import '../../services/tracking_service.dart';

final trackingServiceProvider = Provider((ref) => TrackingService());

final trackingDataProvider = FutureProvider.family<TrackingData, String>(
  (ref, trackingId) async {
    final service = ref.read(trackingServiceProvider);
    return service.getTrackingInfo(trackingId);
  },
);

class OrderTrackingDialog extends HookConsumerWidget {
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double kHeaderHeight = 64;

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

    // Animation controllers
    final animationController = useAnimationController(
      duration: animationDuration,
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

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) => GestureDetector(
              onTap: handleDismiss,
              child: Container(
                color: Colors.black.withOpacity(0.5 * fadeAnimation.value),
              ),
            ),
          ),

          // Dialog Content
          SlideTransition(
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
                    child: _TrackingDialogContent(
                      trackingId: trackingId,
                      onClose: handleDismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(theme),
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      height: OrderTrackingDialog.kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }
}

class _TrackingIdBadge extends StatelessWidget {
  final String trackingId;

  const _TrackingIdBadge({required this.trackingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.truck,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Tracking #$trackingId',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusCard(shipment: shipment, statusColor: statusColor),
                const SizedBox(height: 16),
                if (shipment.estimatedDeliveryDate != null) ...[
                  _EstimatedDeliveryCard(shipment: shipment),
                  const SizedBox(height: 16),
                ],
                _TrackingHistoryHeader(),
                const SizedBox(height: 12),
                _TrackingHistory(shipment: shipment),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingUtils {
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
    return Card(
      elevation: 0,
      color: statusColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.background,
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
    );
  }
}

class _EstimatedDeliveryCard extends StatelessWidget {
  final Shipment shipment;

  const _EstimatedDeliveryCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(
                      DateTime.parse(shipment.estimatedDeliveryDate!),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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

class _TrackingHistoryHeader extends StatelessWidget {
  const _TrackingHistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(
          FontAwesomeIcons.clockRotateLeft,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Tracking History',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

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
                        color: isFirst ? statusColor : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: isFirst ? statusColor : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.2),
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
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                scan.scanDetail.scanLocation,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  scan.scanDetail.instructions,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
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
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tracking Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tracking information available for this order.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onClose;

  const _ErrorView({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Tracking Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onClose,
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 14),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 