import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/inventory_provider.dart';
import '../providers/partner_provider.dart';
import '../providers/product_provider.dart';

class InventoryLogScreen extends ConsumerStatefulWidget {
  const InventoryLogScreen({super.key});

  @override
  ConsumerState<InventoryLogScreen> createState() => _InventoryLogScreenState();
}

class _InventoryLogScreenState extends ConsumerState<InventoryLogScreen> {
  String _searchQuery = '';
  String _filterType = 'ALL';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(inventoryProvider);

    final filtered = logs.where((log) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = log.documentNumber.toLowerCase().contains(q) ||
          log.reason.toLowerCase().contains(q) ||
          (log.reference?.toLowerCase().contains(q) ?? false) ||
          (log.supplierName?.toLowerCase().contains(q) ?? false) ||
          log.items.any((i) =>
              i.productName.toLowerCase().contains(q) ||
              i.productSku.toLowerCase().contains(q));
      return matchSearch && (_filterType == 'ALL' || log.type == _filterType);
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Log'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.package),
            tooltip: 'Product List',
            onPressed: () => context.go('/inventory/products'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: 'Search logs…',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All', 'ALL'),
                const SizedBox(width: 6),
                _filterChip('IN', 'IN', color: Colors.green),
                const SizedBox(width: 6),
                _filterChip('OUT', 'OUT', color: Colors.orange),
                const SizedBox(width: 6),
                _filterChip('REJECT', 'REJECT', color: Colors.red),
                const Spacer(),
                Text(
                  '${filtered.length} log${filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clipboardList,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No logs found',
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showManualEntrySheet(context),
                          icon: const Icon(LucideIcons.plus, size: 14),
                          label: const Text('Record Movement'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final log = filtered[i];
                      final isExpanded = _expandedId == log.id;
                      final dateStr = DateFormat('MMM d, y · h:mm a')
                          .format(DateTime.parse(log.date));

                      final typeColor = log.type == 'IN'
                          ? Colors.green
                          : log.type == 'OUT'
                              ? Colors.orange
                              : Colors.red;
                      final typeIcon = log.type == 'IN'
                          ? LucideIcons.arrowDownCircle
                          : log.type == 'OUT'
                              ? LucideIcons.arrowUpCircle
                              : LucideIcons.alertCircle;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  typeColor.withValues(alpha: 0.15),
                              child:
                                  Icon(typeIcon, color: typeColor, size: 18),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(log.documentNumber,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                                if (log.supplierName != null)
                                  Text(log.supplierName!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                              ],
                            ),
                            subtitle: Text(
                              '$dateStr · ${log.reason}'
                              '${log.reference != null ? ' · ${log.reference}' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Chip(
                              label: Text(log.type),
                              backgroundColor:
                                  typeColor.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                  color: typeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () => setState(() =>
                                _expandedId = isExpanded ? null : log.id),
                          ),
                          if (isExpanded)
                            Container(
                              color: const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...log.items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(item.productName,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ),
                                            Text('× ${item.quantity}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      )),
                                  if (log.notes != null) ...[
                                    const Divider(),
                                    Text(log.notes!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualEntrySheet(context),
        icon: const Icon(LucideIcons.clipboardEdit),
        label: const Text('Record'),
        tooltip: 'Record stock movement',
      ),
    );
  }

  Widget _filterChip(String label, String value, {Color? color}) {
    final selected = _filterType == value;
    final c = color ?? const Color(0xFF1A73E8);
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showManualEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ManualEntryForm(
        onSaved: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock movement recorded'))),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// Manual Stock Movement Form (Bottom Sheet)
// ────────────────────────────────────────────────────────────────────────────────
class _ManualEntryForm extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _ManualEntryForm({required this.onSaved});

  @override
  ConsumerState<_ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends ConsumerState<_ManualEntryForm> {
  String _type = 'IN';
  Partner? _supplier;
  final _referenceCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Each entry: {product, qty}
  final List<({Product product, int qty})> _entries = [];

  bool _saving = false;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(partnersProvider)
        .where((p) => p.type == 'supplier')
        .toList();
    final products = ref.watch(productsProvider);
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, kb + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Record Stock Movement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Type toggle
          Row(
            children: [
              const Text('Type:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'IN',
                      icon: Icon(LucideIcons.arrowDownCircle, size: 14),
                      label: Text('Incoming (IN)')),
                  ButtonSegment(
                      value: 'REJECT',
                      icon: Icon(LucideIcons.alertCircle, size: 14),
                      label: Text('Rejected')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Supplier dropdown
          if (suppliers.isNotEmpty)
            DropdownButtonFormField<Partner>(
              value: _supplier,
              decoration: InputDecoration(
                labelText: 'Supplier (Optional)',
                prefixIcon: const Icon(LucideIcons.truck, size: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ...suppliers.map((s) => DropdownMenuItem(
                    value: s, child: Text(s.name))),
              ],
              onChanged: (v) => setState(() => _supplier = v),
            ),
          const SizedBox(height: 10),

          // Reference and Reason
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _referenceCtrl,
                  decoration: InputDecoration(
                    labelText: 'PO / Reference',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Notes
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),

          // Product entries
          const Text('Products',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A73E8))),
          const SizedBox(height: 6),

          ..._entries.map((entry) {
            final idx = _entries.indexOf(entry);
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(LucideIcons.package, size: 16),
              title: Text(entry.product.name,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(entry.product.sku,
                  style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.minus, size: 14),
                    onPressed: () => setState(() {
                      if (entry.qty > 1) {
                        _entries[idx] = (product: entry.product, qty: entry.qty - 1);
                      }
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('${entry.qty}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 14),
                    onPressed: () => setState(() {
                      _entries[idx] = (product: entry.product, qty: entry.qty + 1);
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2,
                        size: 14, color: Colors.red),
                    onPressed: () =>
                        setState(() => _entries.removeAt(idx)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),

          // Add product button
          TextButton.icon(
            onPressed: () => _pickProduct(products),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add Product', style: TextStyle(fontSize: 13)),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving || _entries.isEmpty ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Movement'),
            ),
          ),
        ],
      ),
    );
  }

  void _pickProduct(List<Product> products) {
    final alreadyAdded = _entries.map((e) => e.product.id).toSet();
    final available = products.where((p) => !alreadyAdded.contains(p.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All products already added')));
      return;
    }

    Product? selected;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Select Product'),
          content: SizedBox(
            width: 360,
            height: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: available.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final p = available[i];
                return ListTile(
                  dense: true,
                  title: Text(p.name,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${p.sku} · stock: ${p.stock}',
                      style: const TextStyle(fontSize: 11)),
                  selected: selected?.id == p.id,
                  selectedTileColor:
                      const Color(0xFFE8F0FE),
                  onTap: () => setS(() => selected = p),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () {
                      setState(
                          () => _entries.add((product: selected!, qty: 1)));
                      Navigator.pop(ctx);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reason is required')));
      return;
    }
    setState(() => _saving = true);

    final items = _entries
        .map((e) => InventoryLogItem(
              productId: e.product.id,
              productName: e.product.name,
              productSku: e.product.sku,
              quantity: e.qty,
            ))
        .toList();

    await ref.read(inventoryProvider.notifier).recordManualMovement(
          type: _type,
          items: items,
          reason: _reasonCtrl.text.trim(),
          supplierId: _supplier?.id,
          supplierName: _supplier?.name,
          reference: _referenceCtrl.text.trim().isEmpty
              ? null
              : _referenceCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }
}
