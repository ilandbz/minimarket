class CustomerModel {
  final int id;
  final String name;
  final String documentType;
  final String? documentNumber;
  final String? phone;
  final String? email;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    required this.documentType,
    this.documentNumber,
    this.phone,
    this.email,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      documentType: json['document_type'] ?? 'VARIOS',
      documentNumber: json['document_number'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'document_type': documentType,
    'document_number': documentNumber,
    'phone': phone,
    'email': email,
    'address': address,
  };
}
