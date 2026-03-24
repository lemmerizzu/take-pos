import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadProducts();
    return [];
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('products');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      state = decoded.map((e) => Product.fromJson(e)).toList();
    } else {
      // Mock initial products like in the React codebase
      state = [
        Product(
          id: '1',
          name: 'Wireless Mouse',
          price: 29.99,
          stock: 45,
          category: 'Electronics',
          sku: 'ELEC-001',
        ),
        Product(
          id: '2',
          name: 'USB-C Cable',
          price: 12.99,
          stock: 120,
          category: 'Accessories',
          sku: 'ACC-002',
        ),
        Product(
          id: '3',
          name: 'Mechanical Keyboard',
          price: 89.99,
          stock: 23,
          category: 'Electronics',
          sku: 'ELEC-003',
        ),
        Product(
          id: '4',
          name: 'Laptop Stand',
          price: 45.99,
          stock: 34,
          category: 'Accessories',
          sku: 'ACC-004',
        ),
        Product(
          id: '5',
          name: 'Webcam HD',
          price: 69.99,
          stock: 18,
          category: 'Electronics',
          sku: 'ELEC-005',
        ),
        Product(
          id: '6',
          name: 'Phone Case',
          price: 15.99,
          stock: 89,
          category: 'Accessories',
          sku: 'ACC-006',
        ),
        Product(
          id: '7',
          name: 'Bluetooth Speaker',
          price: 54.99,
          stock: 27,
          category: 'Electronics',
          sku: 'ELEC-007',
        ),
        Product(
          id: '8',
          name: 'Screen Protector',
          price: 9.99,
          stock: 156,
          category: 'Accessories',
          sku: 'ACC-008',
        ),
      ];
      _saveProducts();
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'products',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addProduct(Product product) {
    state = [...state, product];
    _saveProducts();
  }

  void updateProduct(String id, Product updatedProduct) {
    state = [
      for (final product in state)
        if (product.id == id) updatedProduct else product,
    ];
    _saveProducts();
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
    _saveProducts();
  }

  void deductStock(List<CartItem> cartItems) {
    state = state.map((product) {
      final cartItem = cartItems.cast<CartItem?>().firstWhere(
        (item) => item?.product.id == product.id,
        orElse: () => null,
      );
      if (cartItem != null) {
        return Product(
          id: product.id,
          name: product.name,
          price: product.price,
          stock: product.stock - cartItem.quantity,
          category: product.category,
          sku: product.sku,
          barcode: product.barcode,
          image: product.image,
        );
      }
      return product;
    }).toList();
    _saveProducts();
  }
}
