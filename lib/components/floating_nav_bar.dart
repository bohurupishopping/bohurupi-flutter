// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavBarItem(
                  icon: Iconsax.home,
                  label: 'Home',
                  isActive: currentRoute == '/',
                  onTap: () {
                    if (currentRoute != '/') {
                      Navigator.pushNamed(context, '/');
                    }
                  },
                ),
                _NavBarItem(
                  icon: Iconsax.shopping_cart,
                  label: 'Orders',
                  isActive: currentRoute == '/woo-orders',
                  onTap: () {
                    if (currentRoute != '/woo-orders') {
                      Navigator.pushNamed(context, '/woo-orders');
                    }
                  },
                ),
                _NavBarItem(
                  icon: Iconsax.timer,
                  label: 'Pending',
                  isActive: currentRoute == '/firebase-pending',
                  onTap: () {
                    if (currentRoute != '/firebase-pending') {
                      Navigator.pushNamed(context, '/firebase-pending');
                    }
                  },
                ),
                _NavBarItem(
                  icon: Iconsax.tick_circle,
                  label: 'Done',
                  isActive: currentRoute == '/firebase-completed',
                  onTap: () {
                    if (currentRoute != '/firebase-completed') {
                      Navigator.pushNamed(context, '/firebase-completed');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
} 