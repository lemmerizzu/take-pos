import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import 'product_provider.dart';

final inventoryProvider =
    NotifierProvider<InventoryNotifier, List<InventoryLog>>(() {
  return InventoryNotifier();
});

class InventoryNotifier extends Notifier<List<InventoryLog>> {
  @override
  List<InventoryLog> build() {
    _loadLogs();
    return [];
  }

  Future<void> _loadLogs() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('inventoryLogs');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded.map((e) => InventoryLog.fromJson(e)).toList();
      }
    } else {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('inventory_logs', orderBy: 'date DESC');
      state = maps.map((e) {
        final m = Map<String, dynamic>.from(e);
        m['items'] = jsonDecode(e['items'] as String);
        return InventoryLog.fromJson(m);
      }).toList();
    }
  }

  Future<void> _saveWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'inventoryLogs', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  String _nextDocNumber(String type) {
    String prefix = 'INV-LOG';
    if (type == 'IN') prefix = 'INV-IN';
    else if (type == 'REJECT') prefix = 'INV-REJ';
    else if (type == 'OUT') prefix = 'INV-OUT';
    else if (type == 'IN_DEFECT') prefix = 'INV-DEF';
    else if (type == 'OUT_CLAIM') prefix = 'INV-CLM';

    final count = state.where((l) => l.type == type).length + 1;
    return '$prefix-${count.toString().padLeft(6, '0')}';
  }

  /// Auto log created by sale or manual action
  Future<void> addInventoryLog({
    required String type,
    required List<InventoryLogItem> items,
    required String reason,
    String? reference,
    String? partnerId,
    String? partnerName,
    String? notes,
  }) async {
    final newLog = InventoryLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentNumber: _nextDocNumber(type),
      date: DateTime.now().toIso8601String(),
      type: type,
      items: items,
      reason: reason,
      reference: reference,
      partnerId: partnerId,
      partnerName: partnerName,
      // Keep legacy fields for a bit or just null them
      supplierId: partnerId,
      supplierName: partnerName,
      notes: notes,
    );

    if (kIsWeb) {
      state = [newLog, ...state];
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      final m = newLog.toJson();
      m['items'] = jsonEncode(m['items']);
      await db.insert('inventory_logs', m);
      state = [newLog, ...state];
    }
  }

  /// Manual entry: IN/REJECT (Supplier) or IN_DEFECT/OUT_CLAIM (Customer)
  Future<void> recordManualMovement({
    required String type,
    required List<InventoryLogItem> items,
    required String reason,
    String? partnerId,
    String? partnerName,
    String? reference,
    String? notes,
  }) async {
    await addInventoryLog(
      type: type,
      items: items,
      reason: reason,
      partnerId: partnerId,
      partnerName: partnerName,
      reference: reference,
      notes: notes,
    );

    // Adjust stock:
    //  IN, IN_DEFECT  → Stock increases (+)
    //  REJECT, OUT_CLAIM → Stock decreases (-)
    final isPositive = type == 'IN' || type == 'IN_DEFECT';
    final sign = isPositive ? 1 : -1;
    
    final adjustments = items
        .map((i) => (productId: i.productId, qty: i.quantity * sign))
        .toList();
    await ref.read(productsProvider.notifier).adjustStock(adjustments);
  }
}

