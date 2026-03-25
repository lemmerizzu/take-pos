import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/product_provider.dart';

// Persists last-used weight unit within the session for autosuggestion
String _sessionLastWeightUnit = 'g';


Color _avatarColor(String name) {
  final colors = [
    const Color(0xFF1A73E8), const Color(0xFF34A853), const Color(0xFFEA4335),
    const Color(0xFFFBBC04), const Color(0xFF9334EA), const Color(0xFF00ACC1),
  ];
  return colors[name.codeUnitAt(0) % colors.length];
}

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
    final filtered = products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: 'Search products…',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} item${filtered.length != 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.package,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No products found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final stockColor = p.stock == 0
                          ? Colors.red
                          : p.stock < 20
                              ? Colors.orange
                              : Colors.green;
                      final stockLabel = p.stock == 0
                          ? 'Out'
                          : p.stock < 20
                              ? 'Low (${p.stock})'
                              : 'In Stock (${p.stock})';

                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: _avatarColor(p.name),
                              child: Text(p.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            if (p.isBundle)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9334EA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.layers,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            if (p.isBundle)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9334EA)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('BUNDLE',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9334EA))),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          [
                            p.sku,
                            p.category,
                            '\$${p.price.toStringAsFixed(2)}',
                            if (p.weight != null && p.weightUnit != null)
                              '${p.weight}${p.weightUnit}',
                          ].join(' · '),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Chip(
                          label: Text(stockLabel),
                          backgroundColor:
                              stockColor.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _showProductDialog(context, p),
                        onLongPress: () => _confirmDelete(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, null),
        tooltip: 'Add Product',
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductFormDialog(
        product: product,
        onSave: (p) {
          final notifier = ref.read(productsProvider.notifier);
          if (product == null) {
            notifier.addProduct(p);
          } else {
            notifier.updateProduct(product.id, p);
          }
          // Remember last used weight unit for autosuggestion
          if (p.weightUnit != null) {
            _sessionLastWeightUnit = p.weightUnit!;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  product == null ? 'Product added' : 'Product updated')));
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// Product Form Dialog — extracted for clarity
// ────────────────────────────────────────────────────────────────────────────────
class _ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  final void Function(Product) onSave;

  const _ProductFormDialog({required this.product, required this.onSave});

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _stock;
  late TextEditingController _category;
  late TextEditingController _sku;
  late TextEditingController _barcode;
  late TextEditingController _weight;

  late String _selectedUnit;
  late bool _isBundle;
  late List<BundleItem> _bundleItems;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name);
    _price = TextEditingController(text: p?.price.toString());
    _stock = TextEditingController(text: p?.stock.toString());
    _category = TextEditingController(text: p?.category);
    _sku = TextEditingController(text: p?.sku);
    _barcode = TextEditingController(text: p?.barcode);
    _weight =
        TextEditingController(text: p?.weight?.toString());
    _selectedUnit =
        p?.weightUnit ?? _sessionLastWeightUnit;
    _isBundle = p?.isBundle ?? false;
    _bundleItems = List.from(p?.bundleItems ?? []);
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _stock, _category, _sku, _barcode, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoGenerateSku() {
    final cat = _category.text.trim();
    setState(() {
      _sku.text = ProductsNotifier.generateSku(cat.isEmpty ? 'PRD' : cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider)
        .where((p) => widget.product == null || p.id != widget.product!.id)
        .toList();

    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Basic Info ──────────────────────────────────────────────────
              _sectionLabel('Basic Information'),
              _field(_name, 'Product Name *'),
              Row(
                children: [
                  Expanded(child: _field(_price, 'Price *', type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_stock, 'Stock *', type: TextInputType.number)),
                ],
              ),
              _field(_category, 'Category *'),

              // ── SKU with Auto-Generate ──────────────────────────────────────
              _sectionLabel('SKU / Barcode'),
              Row(
                children: [
                  Expanded(child: _field(_sku, 'SKU *')),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Auto-generate SKU',
                    child: ElevatedButton.icon(
                      onPressed: _autoGenerateSku,
                      icon: const Icon(LucideIcons.zap, size: 14),
                      label: const Text('Auto',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
              _field(_barcode, 'Barcode (Optional)'),

              // ── Specifications ───────────────────────────────────────────────
              _sectionLabel('Specifications'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _field(_weight, 'Weight / Volume',
                        type: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        items: kWeightUnits
                            .map((u) => DropdownMenuItem(
                                value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedUnit = v ?? 'g'),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bundle / Kit ─────────────────────────────────────────────────
              _sectionLabel('Bundle / Kit'),
              SwitchListTile(
                value: _isBundle,
                title: const Text('This product is a Bundle / Kit',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                    'Contains multiple child products',
                    style: TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() {
                  _isBundle = v;
                  if (!v) _bundleItems.clear();
                }),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              if (_isBundle) ...[
                const SizedBox(height: 8),
                ...List.generate(_bundleItems.length, (i) {
                  final item = _bundleItems[i];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(LucideIcons.package,
                        size: 16, color: Color(0xFF9334EA)),
                    title: Text(item.productName,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(item.productSku,
                        style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('×${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              size: 14, color: Colors.red),
                          onPressed: () =>
                              setState(() => _bundleItems.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _showBundleItemPicker(allProducts),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add Item', style: TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if ([_name, _price, _stock, _category, _sku]
        .any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    final p = Product(
      id: widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      price: double.tryParse(_price.text) ?? 0,
      stock: int.tryParse(_stock.text) ?? 0,
      category: _category.text.trim(),
      sku: _sku.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      weight: _weight.text.trim().isEmpty
          ? null
          : double.tryParse(_weight.text.trim()),
      weightUnit: _weight.text.trim().isEmpty ? null : _selectedUnit,
      isBundle: _isBundle,
      bundleItems: _isBundle && _bundleItems.isNotEmpty ? _bundleItems : null,
    );
    Navigator.pop(context);
    widget.onSave(p);
  }

  void _showBundleItemPicker(List<Product> allProducts) {
    int qty = 1;
    Product? selected;
    // Filter out already added
    final alreadyAdded = _bundleItems.map((b) => b.productId).toSet();
    final available = allProducts
        .where((p) => !p.isBundle && !alreadyAdded.contains(p.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Bundle Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: available
                    .map((p) => DropdownMenuItem(
                        value: p, child: Text('${p.name} (${p.sku})')))
                    .toList(),
                onChanged: (v) => setS(() => selected = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Quantity per bundle:',
                      style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setS(() { if (qty > 1) qty--; }),
                    icon: const Icon(LucideIcons.minus, size: 16),
                  ),
                  Text('$qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    onPressed: () => setS(() => qty++),
                    icon: const Icon(LucideIcons.plus, size: 16),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () {
                      setState(() {
                        _bundleItems.add(BundleItem(
                          productId: selected!.id,
                          productName: selected!.name,
                          productSku: selected!.sku,
                          quantity: qty,
                        ));
                      });
                      Navigator.pop(ctx);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
              letterSpacing: 0.5)),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
