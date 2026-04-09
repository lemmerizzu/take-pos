import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});



class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadProducts();
    return [];
  }

  static List<Product> get _seedData => [
        Product(id: '1', name: 'Wireless Mouse', price: 29.99, stock: 45, category: 'Electronics', sku: 'ELEC-001', weight: 95, weightUnit: 'g'),
        Product(id: '2', name: 'USB-C Cable', price: 12.99, stock: 120, category: 'Accessories', sku: 'ACC-002', weight: 50, weightUnit: 'g'),
        Product(id: '3', name: 'Mechanical Keyboard', price: 89.99, stock: 23, category: 'Electronics', sku: 'ELEC-003', weight: 850, weightUnit: 'g'),
        Product(id: '4', name: 'Laptop Stand', price: 45.99, stock: 34, category: 'Accessories', sku: 'ACC-004', weight: 400, weightUnit: 'g'),
        Product(id: '5', name: 'Webcam HD', price: 69.99, stock: 18, category: 'Electronics', sku: 'ELEC-005', weight: 180, weightUnit: 'g'),
        Product(id: '6', name: 'Phone Case', price: 15.99, stock: 89, category: 'Accessories', sku: 'ACC-006', weight: 30, weightUnit: 'g'),
        Product(id: '7', name: 'Bluetooth Speaker', price: 54.99, stock: 27, category: 'Electronics', sku: 'ELEC-007', weight: 300, weightUnit: 'g'),
        Product(id: '8', name: 'Screen Protector', price: 9.99, stock: 156, category: 'Accessories', sku: 'ACC-008', weight: 15, weightUnit: 'g'),
      ];

  Future<void> _loadProducts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('products');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded.map((e) => _fromWebJson(e)).toList();
      } else {
        state = _seedData;
        await _saveWeb();
      }
    } else {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('products');
      if (maps.isNotEmpty) {
        state = maps.map((e) => _fromDbMap(e)).toList();
      } else {
        for (var p in _seedData) {
          await db.insert('products', _toDbMap(p));
        }
        state = _seedData;
      }
    }
  }

  // Web: bundleItems stored as nested JSON
  Product _fromWebJson(Map<String, dynamic> e) {
    return Product.fromJson(e);
  }

  // Native DB: bundleItems stored as JSON string column
  Product _fromDbMap(Map<String, dynamic> e) {
    final map = Map<String, dynamic>.from(e);
    if (map['bundleItems'] is String) {
      final raw = jsonDecode(map['bundleItems'] as String);
      map['bundleItems'] = raw is List ? raw : null;
    }
    return Product.fromJson(map);
  }

  Map<String, dynamic> _toDbMap(Product p) {
    final m = p.toJson();
    m['bundleItems'] = p.bundleItems != null
        ? jsonEncode(p.bundleItems!.map((b) => b.toJson()).toList())
        : null;
    return m;
  }

  Future<void> _saveWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'products',
        jsonEncode(state.map((p) {
          final m = p.toJson();
          if (p.bundleItems != null) {
            m['bundleItems'] = p.bundleItems!.map((b) => b.toJson()).toList();
          }
          return m;
        }).toList()));
  }

  /// Auto-generate a SKU based on category prefix + 6 random digits
  static String generateSku(String category) {
    final prefix = category.isEmpty
        ? 'PRD'
        : category.substring(0, min(4, category.length)).toUpperCase();
    final num = Random().nextInt(900000) + 100000;
    return '$prefix-$num';
  }

  Future<void> addProduct(Product product) async {
    if (kIsWeb) {
      state = [...state, product];
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.insert('products', _toDbMap(product));
      state = [...state, product];
    }
  }

  Future<void> updateProduct(String id, Product updatedProduct) async {
    if (kIsWeb) {
      state = [for (final p in state) if (p.id == id) updatedProduct else p];
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.update('products', _toDbMap(updatedProduct),
          where: 'id = ?', whereArgs: [id]);
      state = [for (final p in state) if (p.id == id) updatedProduct else p];
    }
  }

  Future<void> deleteProduct(String id) async {
    if (kIsWeb) {
      state = state.where((p) => p.id != id).toList();
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      state = state.where((p) => p.id != id).toList();
    }
  }

  /// Increment stock for a list of {productId, qty} — used by manual IN log
  Future<void> adjustStock(List<({String productId, int qty})> adjustments) async {
    final updated = state.map((p) {
      final adj = adjustments.cast<({String productId, int qty})?>().firstWhere(
            (a) => a?.productId == p.id,
            orElse: () => null,
          );
      if (adj == null) return p;
      return p.copyWith(stock: p.stock + adj.qty);
    }).toList();
    state = updated;

    if (kIsWeb) {
      await _saveWeb();
    } else {
      final db = await DatabaseHelper.instance.database;
      for (final adj in adjustments) {
        await db.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [adj.qty, adj.productId]);
      }
    }
  }

  /// Deduct stock after sale — handles bundles by expanding child items
  void deductStockLocally(List<CartItem> cartItems) {
    // Expand bundles into individual child deductions
    final Map<String, int> deductions = {};
    for (final cartItem in cartItems) {
      final product = cartItem.product;
      if (product.isBundle && product.bundleItems != null) {
        for (final child in product.bundleItems!) {
          deductions[child.productId] =
              (deductions[child.productId] ?? 0) + child.quantity * cartItem.quantity;
        }
      } else {
        deductions[product.id] =
            (deductions[product.id] ?? 0) + cartItem.quantity;
      }
    }

    state = state.map((product) {
      final deduct = deductions[product.id];
      if (deduct == null) return product;
      return product.copyWith(stock: product.stock - deduct);
    }).toList();

    if (kIsWeb) _saveWeb();
  }
}
