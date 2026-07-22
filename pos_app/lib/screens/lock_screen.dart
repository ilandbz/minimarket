import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Lanzar el lector de huellas automáticamente después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleUnlock();
    });
  }

  void _handleUnlock() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.unlockWithBiometrics();
    
    if (!success && authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Usuario';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkGradient
              : const LinearGradient(
                  colors: [Color(0xFFEEF2F6), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 72,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Minimarket POS',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.primaryDark,
                        ),
                  ),
                  const Text(
                    'Sesión Activa - POS Protegido',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 50),

                  // Caja de Desbloqueo
                  Card(
                    elevation: isDark ? 8 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hola, $userName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El acceso está protegido por huella digital.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Botón gigante de huella
                          InkWell(
                            onTap: _handleUnlock,
                            borderRadius: BoxShape.circle == true ? BorderRadius.zero : BorderRadius.circular(40), // Safe fallback
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                size: 80,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Presiona el icono o escanea tu huella para desbloquear',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón para salir/cambiar de usuario
                  TextButton.icon(
                    onPressed: () {
                      authProvider.logout();
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                    label: const Text(
                      'Cerrar Sesión / Ingresar con otro usuario',
                      style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
