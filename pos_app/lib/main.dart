import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/vendedor_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar ApiService (cargar URL guardada)
  await ApiService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedUser()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..fetchProducts()..fetchCategories()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimarket POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Cambia automáticamente según el sistema
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Redirección por roles
    if (authProvider.isAdmin) {
      return const AdminDashboardScreen();
    } else {
      return const VendedorDashboardScreen();
    }
  }
}
