import 'product.dart';

class CartItemDiscount {
  final String type; // 'percentage' | 'fixed'
  final double value;

  CartItemDiscount({required this.type, required this.value});

  factory CartItemDiscount.fromJson(Map<String, dynamic> json) {
    return CartItemDiscount(
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'value': value};
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final CartItemDiscount? discount;

  CartItem({required this.product, required this.quantity, this.discount});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
      discount: json['discount'] != null
          ? CartItemDiscount.fromJson(json['discount'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      if (discount != null) 'discount': discount!.toJson(),
    };
  }
}
