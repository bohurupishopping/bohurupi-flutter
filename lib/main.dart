import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'services/environment_service.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/orders/woo_orders_page.dart';
import 'pages/orders/firebase_completed_page.dart';
import 'pages/orders/firebase_pending_page.dart';
import 'pages/orders/create_order_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment service
  final env = EnvironmentService.instance;
  if (env.isDevelopment) {
    debugPrint('Running in DEVELOPMENT mode');
    debugPrint('Base URL: ${env.baseUrl}');
  }

  runApp(const ProviderScope(child: MainApp()));
}

/// Global provider for environment service
final environmentProvider = Provider<EnvironmentService>((ref) {
  return EnvironmentService.instance;
});

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the environment service
    final env = ref.watch(environmentProvider);
    
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
        '/create-order': (context) => const CreateOrderPage(),
      },
    );
  }
}
