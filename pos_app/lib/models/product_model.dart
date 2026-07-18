import 'category_model.dart';

class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final String? barcode;
  final double price;
  final double costPrice;
  final int stock;
  final int alertStock;
  final String status;
  final String? imageUrl;
  final CategoryModel? category;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.barcode,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.alertStock,
    required this.status,
    this.imageUrl,
    this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      barcode: json['barcode'],
      price: double.parse(json['price'].toString()),
      costPrice: double.parse((json['cost_price'] ?? 0.0).toString()),
      stock: json['stock'],
      alertStock: json['alert_stock'] ?? 5,
      status: json['status'] ?? 'active',
      imageUrl: json['image_url'],
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'barcode': barcode,
    'price': price,
    'cost_price': costPrice,
    'stock': stock,
    'alert_stock': alertStock,
    'status': status,
    'image_url': imageUrl,
  };
}
