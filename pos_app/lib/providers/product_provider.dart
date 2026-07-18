import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar Categorías
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((c) => CategoryModel.fromJson(c)).toList();
      } else {
        _errorMessage = 'Error al cargar categorías.';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar Productos (con filtro de búsqueda opcional)
  Future<void> fetchProducts({String? search, int? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String endpoint = 'products';
      List<String> params = [];
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (categoryId != null) {
        params.add('category_id=$categoryId');
      }
      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _products = data.map((p) => ProductModel.fromJson(p)).toList();
      } else {
        _errorMessage = 'Error al cargar productos.';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Buscar por Código de Barras (retorna un producto si lo encuentra)
  Future<ProductModel?> findByBarcode(String barcode) async {
    try {
      final response = await ApiService.get('products/barcode/$barcode');
      if (response.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  // Guardar/Actualizar Producto
  Future<bool> saveProduct(Map<String, dynamic> productData, {int? id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = id == null
          ? await ApiService.post('products', productData)
          : await ApiService.put('products/$id', productData);

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchProducts(); // Recargar
        return true;
      }
      return false;
    } catch (_) {
      _isLoading = false;
      return false;
    }
  }

  // Eliminar Producto
  Future<bool> deleteProduct(int id) async {
    try {
      final response = await ApiService.delete('products/$id');
      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Guardar/Actualizar Categoría
  Future<bool> saveCategory(Map<String, dynamic> categoryData, {int? id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = id == null
          ? await ApiService.post('categories', categoryData)
          : await ApiService.put('categories/$id', categoryData);

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchCategories(); // Recargar
        return true;
      }
      return false;
    } catch (_) {
      _isLoading = false;
      return false;
    }
  }

  // Eliminar Categoría
  Future<bool> deleteCategory(int id) async {
    try {
      final response = await ApiService.delete('categories/$id');
      if (response.statusCode == 200) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
