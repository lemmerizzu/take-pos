class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String sku;
  final String? barcode;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.sku,
    this.barcode,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      category: json['category'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (image != null) 'image': image,
    };
  }
}
