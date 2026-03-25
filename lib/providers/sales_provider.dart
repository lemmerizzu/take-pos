import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import 'cart_provider.dart';
import 'product_provider.dart';
import 'inventory_provider.dart';
import 'partner_provider.dart';

final salesProvider = NotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});

class SalesNotifier extends Notifier<List<Sale>> {
  @override
  List<Sale> build() {
    _loadSales();
    return [];
  }

  Future<void> _loadSales() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('sales');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded.map((e) => Sale.fromJson(e)).toList();
      }
    } else {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps =
          await db.query('sales', orderBy: 'date DESC');
      state = maps.map((e) {
        final decodedItems = jsonDecode(e['items'] as String);
        final map = Map<String, dynamic>.from(e);
        map['items'] = decodedItems;
        return Sale.fromJson(map);
      }).toList();
    }
  }

  Future<void> _saveWeb(List<Sale> sales) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
  }

  Future<void> completeSale(String paymentMethod) async {
    final cartState = ref.read(cartProvider);
    final cart = cartState.items;

    if (cart.isEmpty) return;

    final subtotal = cart.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    final itemDiscountAmount = cart.fold<double>(0, (sum, item) {
      if (item.discount == null) return sum;
      final itemTotal = item.product.price * item.quantity;
      if (item.discount!.type == 'percentage') {
        return sum + (itemTotal * item.discount!.value / 100);
      } else {
        return sum + item.discount!.value;
      }
    });

    double cartDiscountAmount = 0;
    if (cartState.cartDiscount != null) {
      final subtotalAfterItemDiscounts = subtotal - itemDiscountAmount;
      if (cartState.cartDiscount!.type == 'percentage') {
        cartDiscountAmount =
            subtotalAfterItemDiscounts * cartState.cartDiscount!.value / 100;
      } else {
        cartDiscountAmount = cartState.cartDiscount!.value;
      }
    }

    final totalDiscount = itemDiscountAmount + cartDiscountAmount;
    final subtotalAfterDiscount = subtotal - totalDiscount;
    final tax = subtotalAfterDiscount * 0.1;
    final total = subtotalAfterDiscount + tax;

    final saleId = DateTime.now().millisecondsSinceEpoch.toString();

    Partner? customer;
    if (cartState.selectedCustomerId != null) {
      final partners = ref.read(partnersProvider);
      try {
        customer = partners.firstWhere((p) => p.id == cartState.selectedCustomerId);
      } catch (_) {}
    }

    final sale = Sale(
      id: saleId,
      date: DateTime.now().toIso8601String(),
      items: cart,
      subtotal: subtotal,
      discount: totalDiscount,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      customerId: customer?.id,
      customerName: customer?.name,
    );

    final saleDocNumber = 'SALE-${saleId.substring(saleId.length >= 6 ? saleId.length - 6 : 0)}';
    final logItems = cart.map((item) => InventoryLogItem(
      productId: item.product.id,
      productName: item.product.name,
      productSku: item.product.sku,
      quantity: item.quantity,
    )).toList();

    if (kIsWeb) {
      // Web: update state directly, persist with SharedPreferences
      final newSales = [sale, ...state];
      state = newSales;
      await _saveWeb(newSales);

      ref.read(productsProvider.notifier).deductStockLocally(cart);
      await ref.read(inventoryProvider.notifier).addInventoryLog(
        type: 'OUT',
        items: logItems,
        reason: 'Sale',
        reference: saleDocNumber,
      );
    } else {
      // Native: wrap everything in a single atomic DB transaction
      final inventoryLog = InventoryLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentNumber: 'INV-OUT-$saleId',
        date: DateTime.now().toIso8601String(),
        type: 'OUT',
        items: logItems,
        reason: 'Sale',
        reference: saleDocNumber,
      );

      final db = await DatabaseHelper.instance.database;
      try {
        await db.transaction((txn) async {
          final saleMap = sale.toJson();
          saleMap['items'] = jsonEncode(saleMap['items']);
          await txn.insert('sales', saleMap);

          final logMap = inventoryLog.toJson();
          logMap['items'] = jsonEncode(logMap['items']);
          await txn.insert('inventory_logs', logMap);

          for (final item in cart) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock - ? WHERE id = ?',
              [item.quantity, item.product.id],
            );
          }
        });

        state = [sale, ...state];
        ref.read(productsProvider.notifier).deductStockLocally(cart);
      } catch (e) {
        // ignore: avoid_print
        print('Checkout Transaction Failed: $e');
      }
    }

    ref.read(cartProvider.notifier).clearCart();
  }
}
