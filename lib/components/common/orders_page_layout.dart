import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:ui';
import '../firebase_order/firebase_order_table.dart';
import './floating_nav_bar.dart';
import '../../models/firebase_order.dart';

class OrdersPageLayout extends HookWidget {
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

    // Animation controller for background effects
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 1500),
    );

    // Background animation
    final backgroundAnimation = useAnimation(
      Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Start the infinite animation
    useEffect(() {
      animationController.repeat(reverse: true);
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1 * backgroundAnimation),
                      theme.colorScheme.secondary.withOpacity(0.12 * backgroundAnimation),
                      theme.colorScheme.tertiary.withOpacity(0.1 * backgroundAnimation),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  backgroundBlendMode: BlendMode.overlay,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 30 * backgroundAnimation,
                    sigmaY: 30 * backgroundAnimation,
                  ),
                  child: Container(
                    color: theme.colorScheme.background.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),

          // Main content with glassmorphism
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHeader(theme, isSmallScreen),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSmallScreen) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Title Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                      theme.colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            theme.colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
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
              const SizedBox(width: 12),

              // Search Field
              Expanded(
                child: Container(
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.9),
                        theme.colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Order Count and Refresh Button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    width: 0.5,
                  ),
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
              _buildRefreshButton(theme, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withOpacity(0.7),
            theme.colorScheme.secondaryContainer.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: FilledButton.tonal(
        onPressed: onRefresh,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
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
      ),
    );
  }
} 