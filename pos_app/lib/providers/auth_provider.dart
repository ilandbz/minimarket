import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  // Cargar usuario persistido
  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    final token = prefs.getString('auth_token');

    if (userJson != null && token != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  // Iniciar Sesión
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
