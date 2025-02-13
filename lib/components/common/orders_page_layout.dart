import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../firebase_order/firebase_order_table.dart';
import './floating_nav_bar.dart';
import '../../models/firebase_order.dart';

class OrdersPageLayout extends StatelessWidget {
  const OrdersPageLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.orders,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onSearch,
    required this.onPageChanged,
    required this.currentPage,
    required this.totalPages,
  });

  final String title;
  final IconData icon;
  final List<FirebaseOrder> orders;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(String) onSearch;
  final void Function(int) onPageChanged;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.8),
                      theme.colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(theme, isSmallScreen),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: onRefresh,
                        child: FirebaseOrderTable(
                          orders: orders,
                          isLoading: isLoading,
                          error: error,
                          onPageChanged: onPageChanged,
                          currentPage: currentPage,
                          totalPages: totalPages,
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
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title with custom container
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
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
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        icon,
                        size: isSmallScreen ? 10 : 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Order Count Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${orders.length} Orders',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              // Refresh Button
              _buildRefreshButton(theme, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          // Search Field
          Container(
            height: isSmallScreen ? 32 : 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearch,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  size: isSmallScreen ? 14 : 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme, bool isSmallScreen) {
    return FilledButton.tonal(
      onPressed: onRefresh,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.refresh,
            size: isSmallScreen ? 10 : 12,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            'Refresh',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
} 