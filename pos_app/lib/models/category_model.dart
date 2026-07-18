class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final int? productsCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.productsCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      productsCount: json['products_count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}
