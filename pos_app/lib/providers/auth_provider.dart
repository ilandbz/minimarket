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

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isBiometricEnabled => _isBiometricEnabled;

  // Cargar usuario persistido y preferencia biométrica
  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    final token = prefs.getString('auth_token');
    _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (userJson != null && token != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
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

  // Autenticar e ingresar con Huella Digital
  Future<bool> authenticateWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verificar soporte físico
      final supported = await checkBiometricsSupport();
      if (!supported) {
        _errorMessage = 'Autenticación biométrica no disponible.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Ejecutar escaneo de huella
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Escanea tu huella para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('auth_user');
        final token = prefs.getString('auth_token');

        if (userJson != null && token != null) {
          _user = UserModel.fromJson(jsonDecode(userJson));
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Primero debes iniciar sesión con contraseña una vez para registrar tus datos.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Autenticación biométrica fallida o cancelada.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error biométrico: $e';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
