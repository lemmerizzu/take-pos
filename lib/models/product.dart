import 'bundle_item.dart';
export 'bundle_item.dart';

// Weight units for product specifications
const kWeightUnits = ['g', 'kg', 'ml', 'L', 'oz', 'lb', 'pcs', 'box'];

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String sku;
  final String? barcode;
  final String? image;

  // Spec fields
  final double? weight;
  final String? weightUnit; // from kWeightUnits

  // Bundle/Kit
  final bool isBundle;
  final List<BundleItem>? bundleItems;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.sku,
    this.barcode,
    this.image,
    this.weight,
    this.weightUnit,
    this.isBundle = false,
    this.bundleItems,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<BundleItem>? items;
    if (json['bundleItems'] != null) {
      final raw = json['bundleItems'];
      if (raw is List) {
        items = raw
            .map((e) => BundleItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      category: json['category'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      image: json['image'] as String?,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      weightUnit: json['weightUnit'] as String?,
      isBundle: (json['isBundle'] as int? ?? 0) == 1,
      bundleItems: items,
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
      if (weight != null) 'weight': weight,
      if (weightUnit != null) 'weightUnit': weightUnit,
      'isBundle': isBundle ? 1 : 0,
      // bundleItems is serialized separately as JSON in DB
    };
  }

  /// Returns a copy with bundleItems embedded (for UI state only)
  Product copyWith({
    String? id, String? name, double? price, int? stock,
    String? category, String? sku, String? barcode, String? image,
    double? weight, String? weightUnit, bool? isBundle,
    List<BundleItem>? bundleItems,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      image: image ?? this.image,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      isBundle: isBundle ?? this.isBundle,
      bundleItems: bundleItems ?? this.bundleItems,
    );
  }
}
