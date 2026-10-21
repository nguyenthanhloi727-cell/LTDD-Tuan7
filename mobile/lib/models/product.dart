class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final int quantity; // 0 = het hang
  final int? categoryId; // null = chua phan loai
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.quantity = 0,
    this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      quantity: (json['quantity'] as int?) ?? 0,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'categoryId': categoryId,
      };
}
