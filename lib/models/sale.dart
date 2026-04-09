import 'cart_item.dart';

class Sale {
  final String id;
  final String date;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod; // 'cash' | 'card' | 'digital'
  final String? customerId;
  final String? customerName;

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      date: json['date'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
    };
  }
}
