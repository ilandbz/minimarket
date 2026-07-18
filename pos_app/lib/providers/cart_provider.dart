import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
  double get costSubtotal => product.costPrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  bool _isProcessing = false;

  Map<int, CartItem> get items => _items;
  bool get isProcessing => _isProcessing;

  int get itemsCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  // IGV de Perú (18% incluido)
  double get totalIgv {
    return totalAmount - totalGravada;
  }

  double get totalGravada {
    return totalAmount / 1.18;
  }

  // Agregar al carrito
  bool addProduct(ProductModel product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      int currentQty = _items[product.id]!.quantity;
      if (product.stock < currentQty + quantity) {
        return false; // Stock insuficiente
      }
      _items[product.id]!.quantity += quantity;
    } else {
      if (product.stock < quantity) {
        return false; // Stock insuficiente
      }
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
    return true;
  }

  // Cambiar cantidad directamente
  bool updateQuantity(int productId, int quantity) {
    if (!_items.containsKey(productId)) return false;
    
    if (quantity <= 0) {
      _items.remove(productId);
      notifyListeners();
      return true;
    }

    final product = _items[productId]!.product;
    if (product.stock < quantity) {
      return false; // Stock insuficiente
    }

    _items[productId]!.quantity = quantity;
    notifyListeners();
    return true;
  }

  // Quitar del carrito
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Limpiar carrito
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Procesar cobro y enviar venta a la API
  Future<Map<String, dynamic>?> checkout({
    required String paymentMethod,
    required double amountPaid,
    required String documentType,
    CustomerModel? customer,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      int? customerId = customer?.id;

      // Si se ingresó DNI/RUC pero el cliente no está guardado (id = 0 o similar), crearlo
      if (customer != null && customerId == null) {
        final custResponse = await ApiService.post('customers', customer.toJson());
        if (custResponse.statusCode == 201) {
          final custData = jsonDecode(custResponse.body);
          customerId = custData['customer']['id'];
        } else {
          _isProcessing = false;
          notifyListeners();
          return {
            'success': false,
            'message': 'Error al registrar el cliente para el comprobante.'
          };
        }
      }

      // Preparar estructura de la venta
      final List<Map<String, dynamic>> saleItems = [];
      _items.forEach((productId, item) {
        saleItems.add({
          'product_id': productId,
          'quantity': item.quantity,
        });
      });

      final saleBody = {
        'customer_id': customerId,
        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'document_type': documentType,
        'items': saleItems
      };

      final response = await ApiService.post('sales', saleBody);
      final responseData = jsonDecode(response.body);

      _isProcessing = false;
      notifyListeners();

      if (response.statusCode == 201) {
        clear(); // Venta exitosa, vaciar carrito
        return {
          'success': true,
          'sale': responseData['sale'],
          'sunat': responseData['sunat']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Error desconocido al procesar la venta.',
          'error': responseData['error']
        };
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error al conectar con la API: $e'
      };
    }
  }
}
