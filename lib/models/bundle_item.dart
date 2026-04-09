class BundleItem {
  final String productId;
  final String productName; // snapshot for display
  final String productSku;
  final int quantity;

  BundleItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
  });

  factory BundleItem.fromJson(Map<String, dynamic> json) {
    return BundleItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productSku': productSku,
        'quantity': quantity,
      };
}
