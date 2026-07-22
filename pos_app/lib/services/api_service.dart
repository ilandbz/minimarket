import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrl = 'https://apiminimarket.macrocompany.net.pe/api'; // IP por defecto para Emulador Android

  // Inicializar la URL desde las preferencias si existe
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('api_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      _baseUrl = customUrl;
    }
  }

  // Guardar una nueva URL de API (por si se conecta a un servidor local wifi, ej: 192.168.1.50:8000)
  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', newUrl);
  }

  static String get baseUrl => _baseUrl;

  // Obtener Token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Cabeceras estándar
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Petición GET
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse('$_baseUrl/$endpoint'), headers: headers);
  }

  // Petición POST
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // Petición PUT
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // Petición DELETE
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse('$_baseUrl/$endpoint'), headers: headers);
  }
}
