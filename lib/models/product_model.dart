class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'],
      inStock: json['in_stock'] == 1 || json['in_stock'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'in_stock': inStock,
    };
  }
}
