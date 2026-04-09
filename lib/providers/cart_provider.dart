import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

class CartState {
  final List<CartItem> items;
  final Discount? cartDiscount;
  final String? selectedCustomerId;

  CartState({
    this.items = const [],
    this.cartDiscount,
    this.selectedCustomerId,
  });

  CartState copyWith({
    List<CartItem>? items,
    Discount? cartDiscount,
    String? selectedCustomerId,
    bool clearDiscount = false,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      cartDiscount: clearDiscount ? null : (cartDiscount ?? this.cartDiscount),
      selectedCustomerId: clearCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addToCart(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = CartItem(
        product: product,
        quantity: updatedItems[existingIndex].quantity + 1,
        discount: updatedItems[existingIndex].discount,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product, quantity: 1),
        ],
      );
    }
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.product.id == productId) {
          return CartItem(
            product: item.product,
            quantity: quantity,
            discount: item.discount,
          );
        }
        return item;
      }).toList(),
    );
  }

  void updateItemDiscount(String productId, CartItemDiscount? discount) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.product.id == productId) {
          return CartItem(
            product: item.product,
            quantity: item.quantity,
            discount: discount,
          );
        }
        return item;
      }).toList(),
    );
  }

  void setCartDiscount(Discount? discount) {
    state = state.copyWith(
      cartDiscount: discount,
      clearDiscount: discount == null,
    );
  }

  void setSelectedCustomerId(String? customerId) {
    state = state.copyWith(
      selectedCustomerId: customerId,
      clearCustomer: customerId == null,
    );
  }

  void clearCart() {
    state = CartState();
  }
}
