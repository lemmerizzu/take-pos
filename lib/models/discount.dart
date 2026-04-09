class Discount {
  final String type; // 'percentage' | 'fixed'
  final double value;
  final String appliedTo; // 'cart' | 'item'

  Discount({required this.type, required this.value, required this.appliedTo});

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      appliedTo: json['appliedTo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'value': value, 'appliedTo': appliedTo};
  }
}
