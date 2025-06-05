class Product {
  final int? id;
  final String barcode;
  final String name;
  final int quantity;
  final String type;
  final String? imageUrl;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.quantity,
    required this.type,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'quantity': quantity,
      'type': type,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      quantity: map['quantity'],
      type: map['type'],
      imageUrl: map['imageUrl'],
    );
  }
}