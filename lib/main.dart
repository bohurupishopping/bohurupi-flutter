import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/orders/woo_orders_page.dart';
import 'pages/orders/firebase_completed_page.dart';
import 'pages/orders/firebase_pending_page.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/woo-orders': (context) => const WooOrdersPage(),
        '/firebase-completed': (context) => const FirebaseCompletedPage(),
        '/firebase-pending': (context) => const FirebasePendingPage(),
      },
    );
  }
}
