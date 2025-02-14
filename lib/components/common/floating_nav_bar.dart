// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import 'dart:async';

class FloatingNavBar extends StatefulWidget {
  final ScrollController? scrollController;
  final bool showOnPages;
  
  const FloatingNavBar({
    super.key, 
    this.scrollController,
    this.showOnPages = true,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isVisible = true;
  double _lastScrollPosition = 0;
  Timer? _scrollThrottleTimer;
  static const _scrollThrottleDuration = Duration(milliseconds: 100);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.value = 1;
    _setupScrollListener();
  }

  void _setupScrollListener() {
    widget.scrollController?.addListener(() {
      if (_scrollThrottleTimer?.isActive ?? false) return;
      
      _scrollThrottleTimer = Timer(_scrollThrottleDuration, () {
        final currentScroll = widget.scrollController!.position.pixels;
        if (currentScroll <= 0) {
          _showNavBar();
        } else if ((currentScroll - _lastScrollPosition).abs() > 10) {
          if (currentScroll > _lastScrollPosition) {
            _hideNavBar();
          } else {
            _showNavBar();
          }
        }
        _lastScrollPosition = currentScroll;
      });
    });
  }

  void _showNavBar() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
  }

  void _hideNavBar() {
    if (_isVisible) {
      setState(() => _isVisible = false);
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollThrottleTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    
    // Only show on main pages
    if (!widget.showOnPages || currentRoute.contains('/components/')) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 100 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        ),
        child: _OptimizedNavBar(currentRoute: currentRoute),
      ),
    );
  }
}

@immutable
class _OptimizedNavBar extends StatelessWidget {
  final String currentRoute;

  const _OptimizedNavBar({
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.65),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OptimizedNavBarItem(
                  icon: Iconsax.home,
                  label: 'Home',
                  isActive: currentRoute == '/',
                  route: '/',
                ),
                _OptimizedNavBarItem(
                  icon: Iconsax.shopping_cart,
                  label: 'Orders',
                  isActive: currentRoute == '/woo-orders',
                  route: '/woo-orders',
                ),
                _OptimizedNavBarItem(
                  icon: Iconsax.add_circle,
                  label: 'Create',
                  isActive: currentRoute == '/create-order',
                  route: '/create-order',
                ),
                _OptimizedNavBarItem(
                  icon: Iconsax.timer,
                  label: 'Pending',
                  isActive: currentRoute == '/firebase-pending',
                  route: '/firebase-pending',
                ),
                _OptimizedNavBarItem(
                  icon: Iconsax.tick_circle,
                  label: 'Done',
                  isActive: currentRoute == '/firebase-completed',
                  route: '/firebase-completed',
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
class _OptimizedNavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String route;

  const _OptimizedNavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              Navigator.pushNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isActive 
                ? Colors.white.withOpacity(0.15) 
                : Colors.transparent,
              border: isActive
                ? Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  )
                : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.2,
                    fontSize: 9,
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