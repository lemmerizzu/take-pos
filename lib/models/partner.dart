class Partner {
  final String id;
  final String name;
  final String type; // 'customer' | 'supplier'
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    this.email,
    this.phone,
    this.address,
    this.notes,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }
}
