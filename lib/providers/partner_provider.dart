import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

final partnersProvider = NotifierProvider<PartnersNotifier, List<Partner>>(() {
  return PartnersNotifier();
});

class PartnersNotifier extends Notifier<List<Partner>> {
  @override
  List<Partner> build() {
    _loadPartners();
    return [];
  }

  Future<void> _loadPartners() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('partners');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded.map((e) => Partner.fromJson(e)).toList();
      }
    } else {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('partners');
      state = maps.map((e) => Partner.fromJson(e)).toList();
    }
  }

  Future<void> _saveWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partners', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> addPartner(Partner partner) async {
    if (kIsWeb) {
      state = [...state, partner];
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.insert('partners', partner.toJson());
      state = [...state, partner];
    }
  }

  Future<void> updatePartner(String id, Partner updatedPartner) async {
    if (kIsWeb) {
      state = [for (final p in state) if (p.id == id) updatedPartner else p];
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.update('partners', updatedPartner.toJson(), where: 'id = ?', whereArgs: [id]);
      state = [for (final p in state) if (p.id == id) updatedPartner else p];
    }
  }

  Future<void> deletePartner(String id) async {
    if (kIsWeb) {
      state = state.where((p) => p.id != id).toList();
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.delete('partners', where: 'id = ?', whereArgs: [id]);
      state = state.where((p) => p.id != id).toList();
    }
  }
}
