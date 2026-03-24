import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('inventoryLogs');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      state = decoded.map((e) => InventoryLog.fromJson(e)).toList();
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'inventoryLogs',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addInventoryLog({
    required String type,
    required List<InventoryLogItem> items,
    required String reason,
    String? reference,
  }) {
    final typePrefix = type == 'IN'
        ? 'INV-IN'
        : type == 'OUT'
        ? 'INV-OUT'
        : 'INV-REJ';
    final count = state.where((l) => l.type == type).length + 1;
    final documentNumber = '$typePrefix-${count.toString().padLeft(6, '0')}';

    final newLog = InventoryLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentNumber: documentNumber,
      date: DateTime.now().toIso8601String(),
      type: type,
      items: items,
      reason: reason,
      reference: reference,
    );

    state = [newLog, ...state];
    _saveLogs();
  }
}
