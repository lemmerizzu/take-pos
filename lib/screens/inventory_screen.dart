import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/product_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final filteredProducts = products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.clipboardList),
            tooltip: 'Inventory Logs',
            onPressed: () => context.go('/inventory/logs'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showProductDialog(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Search products by name, SKU, or category...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.package,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${product.sku}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Category: ${product.category}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.stock < 20
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Stock: ${product.stock}',
                                style: TextStyle(
                                  color: product.stock < 20
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.pencil,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showProductDialog(context, product),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, product),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameCtrl = TextEditingController(text: product?.name);
    final priceCtrl = TextEditingController(text: product?.price.toString());
    final stockCtrl = TextEditingController(text: product?.stock.toString());
    final categoryCtrl = TextEditingController(text: product?.category);
    final skuCtrl = TextEditingController(text: product?.sku);
    final barcodeCtrl = TextEditingController(text: product?.barcode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: skuCtrl,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              TextField(
                controller: barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Barcode (Optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty ||
                  priceCtrl.text.isEmpty ||
                  stockCtrl.text.isEmpty ||
                  categoryCtrl.text.isEmpty ||
                  skuCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              final newProduct = Product(
                id:
                    product?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                price: double.parse(priceCtrl.text),
                stock: int.parse(stockCtrl.text),
                category: categoryCtrl.text,
                sku: skuCtrl.text,
                barcode: barcodeCtrl.text.isEmpty ? null : barcodeCtrl.text,
              );

              final messenger = ScaffoldMessenger.of(context);
              if (product == null) {
                ref.read(productsProvider.notifier).addProduct(newProduct);
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Product added')),
                );
              } else {
                ref
                    .read(productsProvider.notifier)
                    .updateProduct(product.id, newProduct);
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Product updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
