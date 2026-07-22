import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isLocked = false; // Estado de bloqueo de pantalla inicial

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isLocked => _isLocked;

  // Cargar usuario persistido y preferencia biométrica
  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    final token = prefs.getString('auth_token');
    _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (userJson != null && token != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      // Si la huella está activada, iniciamos la app en estado bloqueado para exigir validación
      _isLocked = _isBiometricEnabled;
    } else {
      _isLocked = false;
    }
    notifyListeners();
  }

  // Verificar si el dispositivo soporta biometría
  Future<bool> checkBiometricsSupport() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  // Habilitar/Deshabilitar huella digital
  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    notifyListeners();
  }

  // Iniciar Sesión con contraseña
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('login', {
        'email': email,
        'password': password,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'];
        _user = UserModel.fromJson(responseData['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
        
        _isLocked = false; // El login exitoso con contraseña no bloquea
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Error de autenticación';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'No se pudo conectar al servidor: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Desbloquear la app con Huella Digital
  Future<bool> unlockWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supported = await checkBiometricsSupport();
      if (!supported) {
        _errorMessage = 'Autenticación biométrica no disponible.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Escanea tu huella para desbloquear el sistema',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isLocked = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Huella no reconocida o validación cancelada.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al desbloquear: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar Sesión
  Future<void> logout() async {
    try {
      await ApiService.post('logout', {});
    } catch (_) {}

    _user = null;
    _isLocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
