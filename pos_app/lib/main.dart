import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  AppLifecycleState? _lastState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si la app vuelve del segundo plano real (paused -> resumed), bloqueamos
    if (state == AppLifecycleState.resumed && _lastState == AppLifecycleState.paused) {
      final authProvider = context.read<AuthProvider>();
      authProvider.lock();
    }
    _lastState = state;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. Si no está autenticado, va al Login con contraseña
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // 2. Si está autenticado pero la app está bloqueada por huella
    if (authProvider.isLocked) {
      return const LockScreen();
    }

    // 3. Redirección por roles si está autenticado y desbloqueado
    if (authProvider.isAdmin) {
      return const AdminDashboardScreen();
    } else {
      return const VendedorDashboardScreen();
    }
  }
}
