import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../firebase_order/firebase_order_table.dart';
import './floating_nav_bar.dart';
import '../../models/firebase_order.dart';

@immutable
class _PageStyles {
  final BoxDecoration pageDecoration;
  final BoxDecoration headerDecoration;
  final BoxDecoration titleDecoration;
  final BoxDecoration searchDecoration;
  final BoxDecoration countDecoration;
  final TextStyle titleStyle;
  final TextStyle searchStyle;
  final TextStyle searchHintStyle;
  final TextStyle countStyle;
  final TextStyle refreshStyle;

  const _PageStyles({
    required this.pageDecoration,
    required this.headerDecoration,
    required this.titleDecoration,
    required this.searchDecoration,
    required this.countDecoration,
    required this.titleStyle,
    required this.searchStyle,
    required this.searchHintStyle,
    required this.countStyle,
    required this.refreshStyle,
  });

  factory _PageStyles.from(ThemeData theme, bool isSmallScreen) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final primaryOpacity02 = theme.colorScheme.primary.withOpacity(0.2);
    final surfaceOpacity95 = theme.colorScheme.surface.withOpacity(0.95);

    return _PageStyles(
      pageDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryOpacity01, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      headerDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: primaryOpacity01,
            width: 0.5,
          ),
        ),
      ),
      titleDecoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primaryOpacity02,
          width: 0.5,
        ),
      ),
      searchDecoration: BoxDecoration(
        color: surfaceOpacity95,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryOpacity01,
          width: 0.5,
        ),
      ),
      countDecoration: BoxDecoration(
        color: primaryOpacity01,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryOpacity01,
          width: 0.5,
        ),
      ),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      searchStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      searchHintStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: isSmallScreen ? 12 : 14,
      ) ?? const TextStyle(),
      countStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
        fontSize: isSmallScreen ? 10 : 12,
      ) ?? const TextStyle(),
      refreshStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: isSmallScreen ? 10 : 12,
      ) ?? const TextStyle(),
    );
  }
}

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

    // Cache styles
    final styles = _PageStyles.from(theme, isSmallScreen);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
          child: Container(
            decoration: styles.pageDecoration,
            child: Column(
              children: [
                _buildHeader(theme, isSmallScreen, styles),
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
      ),
      floatingActionButton: const FloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSmallScreen, _PageStyles styles) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: styles.headerDecoration,
      child: Row(
        children: [
          _TitleBadge(
            title: title,
            icon: icon,
            isSmallScreen: isSmallScreen,
            styles: styles,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SearchField(
              onSearch: onSearch,
              isSmallScreen: isSmallScreen,
              styles: styles,
            ),
          ),
          const SizedBox(width: 12),
          _OrderCountBadge(
            count: orders.length,
            isSmallScreen: isSmallScreen,
            styles: styles,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          _RefreshButton(
            onRefresh: onRefresh,
            isSmallScreen: isSmallScreen,
            styles: styles,
          ),
        ],
      ),
    );
  }
}

class _TitleBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSmallScreen;
  final _PageStyles styles;

  const _TitleBadge({
    required this.title,
    required this.icon,
    required this.isSmallScreen,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: styles.titleDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
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
            style: styles.titleStyle,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final void Function(String) onSearch;
  final bool isSmallScreen;
  final _PageStyles styles;

  const _SearchField({
    required this.onSearch,
    required this.isSmallScreen,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: isSmallScreen ? 32 : 36,
      decoration: styles.searchDecoration,
      child: TextField(
        onChanged: onSearch,
        style: styles.searchStyle,
        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: styles.searchHintStyle,
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
    );
  }
}

class _OrderCountBadge extends StatelessWidget {
  final int count;
  final bool isSmallScreen;
  final _PageStyles styles;

  const _OrderCountBadge({
    required this.count,
    required this.isSmallScreen,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: styles.countDecoration,
      child: Text(
        '$count Orders',
        style: styles.countStyle,
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool isSmallScreen;
  final _PageStyles styles;

  const _RefreshButton({
    required this.onRefresh,
    required this.isSmallScreen,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.tonal(
      onPressed: onRefresh,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
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
            style: styles.refreshStyle,
          ),
        ],
      ),
    );
  }
} 