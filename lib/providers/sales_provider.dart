import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('sales');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      state = decoded.map((e) => Sale.fromJson(e)).toList();
    }
  }

  Future<void> _saveSales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sales',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void completeSale(String paymentMethod) {
    final cartState = ref.read(cartProvider);
    final cart = cartState.items;

    if (cart.isEmpty) return;

    // Calculate subtotal
    final subtotal = cart.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    // Calculate item-level discounts
    final itemDiscountAmount = cart.fold<double>(0, (sum, item) {
      if (item.discount == null) return sum;
      final itemTotal = item.product.price * item.quantity;
      if (item.discount!.type == 'percentage') {
        return sum + (itemTotal * item.discount!.value / 100);
      } else {
        return sum + item.discount!.value;
      }
    });

    // Calculate cart-level discount
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
    final tax = subtotalAfterDiscount * 0.1; // 10% tax applied after discount
    final total = subtotalAfterDiscount + tax;

    final saleId = DateTime.now().millisecondsSinceEpoch.toString();

    // Get customer info if selected
    Partner? customer;
    if (cartState.selectedCustomerId != null) {
      final partners = ref.read(partnersProvider);
      try {
        customer = partners.firstWhere(
          (p) => p.id == cartState.selectedCustomerId,
        );
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

    // Update stock
    ref.read(productsProvider.notifier).deductStock(cart);

    // Create a single batch inventory log for the sale with all items
    final saleDocNumber =
        'SALE-${saleId.substring(saleId.length >= 6 ? saleId.length - 6 : 0)}';
    final logItems = cart
        .map(
          (item) => InventoryLogItem(
            productId: item.product.id,
            productName: item.product.name,
            productSku: item.product.sku,
            quantity: item.quantity,
          ),
        )
        .toList();

    ref
        .read(inventoryProvider.notifier)
        .addInventoryLog(
          type: 'OUT',
          items: logItems,
          reason: 'Sale',
          reference: saleDocNumber,
        );

    state = [sale, ...state];
    _saveSales();

    ref.read(cartProvider.notifier).clearCart();
  }
}
