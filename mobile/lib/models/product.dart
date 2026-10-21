class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
      };
}
