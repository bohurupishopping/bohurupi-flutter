import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../components/common/floating_nav_bar.dart';
import '../../providers/dashboard/dashboard_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadDashboardData());
  }

  Future<void> _handleRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _buildBody(dashboardState),
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(DashboardState dashboardState) {
    if (dashboardState.isLoading && dashboardState.stats.isEmpty) {
      return const _LoadingIndicator();
    }
    
    if (dashboardState.error != null) {
      return _ErrorView(
        error: dashboardState.error!,
        onRetry: _handleRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const RepaintBoundary(child: DashboardHeader()),
                const SizedBox(height: 24),
                RepaintBoundary(
                  child: DashboardStats(
                    key: ValueKey(dashboardState.stats.hashCode),
                    stats: dashboardState.stats,
                  ),
                ),
                if (dashboardState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: _LoadingIndicator()),
                  ),
              ]),
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
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome back!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }
}

class DashboardStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  static const double _spacing = 16.0;
  static const int _crossAxisCount = 2;
  static const double _childAspectRatio = 2.0;

  const DashboardStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - _spacing) / _crossAxisCount;
        final itemHeight = itemWidth / _childAspectRatio;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            _buildStatCard(
              'Total Orders',
              stats['totalOrders']?.toString() ?? '0',
              FontAwesomeIcons.boxOpen,
              Colors.blue,
              itemWidth,
              itemHeight,
            ),
            _buildStatCard(
              'Pending Orders',
              stats['pendingOrders']?.toString() ?? '0',
              FontAwesomeIcons.clockRotateLeft,
              Colors.orange,
              itemWidth,
              itemHeight,
            ),
            _buildStatCard(
              'Completed Orders',
              stats['completedOrders']?.toString() ?? '0',
              FontAwesomeIcons.check,
              Colors.green,
              itemWidth,
              itemHeight,
            ),
            _buildStatCard(
              'Total Sales',
              '\$${((stats['totalSales'] as num?) ?? 0.0).toStringAsFixed(2)}',
              FontAwesomeIcons.dollarSign,
              Colors.purple,
              itemWidth,
              itemHeight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: StatCard(
        key: ValueKey('$title-$value'),
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorWithOpacity = color.withOpacity(0.1);
    
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorWithOpacity,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 