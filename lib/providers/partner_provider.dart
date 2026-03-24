import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('partners');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      state = decoded.map((e) => Partner.fromJson(e)).toList();
    }
  }

  Future<void> _savePartners() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'partners',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addPartner(Partner partner) {
    state = [...state, partner];
    _savePartners();
  }

  void updatePartner(String id, Partner updatedPartner) {
    state = [
      for (final partner in state)
        if (partner.id == id) updatedPartner else partner,
    ];
    _savePartners();
  }

  void deletePartner(String id) {
    state = state.where((p) => p.id != id).toList();
    _savePartners();
  }
}
