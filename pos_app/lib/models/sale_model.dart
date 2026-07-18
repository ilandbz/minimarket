import 'customer_model.dart';
import 'user_model.dart';
import 'product_model.dart';

class SaleItemModel {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double price;
  final double costPrice;
  final double igv;
  final double subtotal;
  final ProductModel? product;

  SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.costPrice,
    required this.igv,
    required this.subtotal,
    this.product,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'],
      saleId: json['sale_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      costPrice: double.parse(json['cost_price'].toString()),
      igv: double.parse(json['igv'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }
}

class SaleModel {
  final int id;
  final int userId;
  final int? customerId;
  final double totalAmount;
  final String paymentMethod;
  final double amountPaid;
  final double changeReturned;
  final String status;
  
  // SUNAT
  final String documentType;
  final String? serie;
  final int? correlativo;
  final String? xmlPath;
  final String? cdrPath;
  final String estadoSunat;
  final String? hashSunat;
  final String? mensajeSunat;
  final double totalIgv;
  final double totalGravada;
  final DateTime createdAt;

  final UserModel? user;
  final CustomerModel? customer;
  final List<SaleItemModel>? items;

  SaleModel({
    required this.id,
    required this.userId,
    this.customerId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeReturned,
    required this.status,
    required this.documentType,
    this.serie,
    this.correlativo,
    this.xmlPath,
    this.cdrPath,
    required this.estadoSunat,
    this.hashSunat,
    this.mensajeSunat,
    required this.totalIgv,
    required this.totalGravada,
    required this.createdAt,
    this.user,
    this.customer,
    this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    List<SaleItemModel>? parsedItems = itemsList?.map((i) => SaleItemModel.fromJson(i)).toList();

    return SaleModel(
      id: json['id'],
      userId: json['user_id'],
      customerId: json['customer_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'],
      amountPaid: double.parse(json['amount_paid'].toString()),
      changeReturned: double.parse((json['change_returned'] ?? 0.0).toString()),
      status: json['status'] ?? 'completed',
      documentType: json['document_type'] ?? 'NOTA_VENTA',
      serie: json['serie'],
      correlativo: json['correlativo'],
      xmlPath: json['xml_path'],
      cdrPath: json['cdr_path'],
      estadoSunat: json['estado_sunat'] ?? 'PENDIENTE',
      hashSunat: json['hash_sunat'],
      mensajeSunat: json['mensaje_sunat'],
      totalIgv: double.parse((json['total_igv'] ?? 0.0).toString()),
      totalGravada: double.parse((json['total_gravada'] ?? 0.0).toString()),
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      customer: json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
      items: parsedItems,
    );
  }
}
