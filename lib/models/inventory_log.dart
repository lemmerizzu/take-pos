class InventoryLogItem {
  final String productId;
  final String productName;
  final String productSku;
  final int quantity;

  InventoryLogItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
  });

  factory InventoryLogItem.fromJson(Map<String, dynamic> json) {
    return InventoryLogItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'quantity': quantity,
    };
  }
}

class InventoryLog {
  final String id;
  final String documentNumber; // e.g., "INV-IN-000001"
  final String date;
  final String type; // 'IN' | 'OUT' | 'REJECT' | 'IN_DEFECT' | 'OUT_CLAIM'
  final List<InventoryLogItem> items;
  final String reason;
  final String? reference; // e.g., Sale ID, Purchase Order, etc.
  final String? partnerId;   // Generalized for Supplier/Customer
  final String? partnerName;
  final String? supplierId;   // Keep for backward compatibility/legacy
  final String? supplierName;
  final String? performedBy;
  final String? notes;

  InventoryLog({
    required this.id,
    required this.documentNumber,
    required this.date,
    required this.type,
    required this.items,
    required this.reason,
    this.reference,
    this.partnerId,
    this.partnerName,
    this.supplierId,
    this.supplierName,
    this.performedBy,
    this.notes,
  });

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id'] as String,
      documentNumber: json['documentNumber'] as String,
      date: json['date'] as String,
      type: json['type'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => InventoryLogItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      reason: json['reason'] as String,
      reference: json['reference'] as String?,
      partnerId: json['partnerId'] as String?,
      partnerName: json['partnerName'] as String?,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      performedBy: json['performedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentNumber': documentNumber,
      'date': date,
      'type': type,
      'items': items.map((e) => e.toJson()).toList(),
      'reason': reason,
      if (reference != null) 'reference': reference,
      if (partnerId != null) 'partnerId': partnerId,
      if (partnerName != null) 'partnerName': partnerName,
      if (supplierId != null) 'supplierId': supplierId,
      if (supplierName != null) 'supplierName': supplierName,
      if (performedBy != null) 'performedBy': performedBy,
      if (notes != null) 'notes': notes,
    };
  }
}
