import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/sales_provider.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  String _searchQuery = '';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesProvider);
    final filtered = sales.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.id.toLowerCase().contains(q) ||
          s.paymentMethod.toLowerCase().contains(q) ||
          (s.customerName?.toLowerCase().contains(q) ?? false) ||
          s.items.any((i) => i.product.name.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySales = sales.where((s) =>
        DateFormat('yyyy-MM-dd').format(DateTime.parse(s.date)) == todayStr);
    final todayRevenue = todaySales.fold<double>(0, (sum, s) => sum + s.total);
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: 'Search sales…',
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
          // Stat bar
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _statBadge(LucideIcons.calendar,
                    "${todaySales.length} today · \$${todayRevenue.toStringAsFixed(2)}",
                    const Color(0xFF1A73E8)),
                const Spacer(),
                _statBadge(LucideIcons.dollarSign,
                    "Total: \$${totalRevenue.toStringAsFixed(2)}",
                    const Color(0xFF34A853)),
              ],
            ),
          ),
          const Divider(),
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
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
                        Icon(LucideIcons.receipt,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No sales yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final sale = filtered[i];
                      final isExpanded = _expandedId == sale.id;
                      final dateStr = DateFormat('MMM d, y · h:mm a')
                          .format(DateTime.parse(sale.date));
                      final payColor = sale.paymentMethod == 'cash'
                          ? const Color(0xFF34A853)
                          : const Color(0xFF1A73E8);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: payColor.withOpacity(0.15),
                              child: Icon(
                                sale.paymentMethod == 'cash'
                                    ? LucideIcons.banknote
                                    : LucideIcons.creditCard,
                                color: payColor,
                                size: 18,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sale.customerName ?? 'Walk-in Customer',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '\$${sale.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1A73E8)),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '$dateStr · ${sale.items.length} item${sale.items.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            trailing: Chip(
                              label: Text(
                                  sale.paymentMethod[0].toUpperCase() +
                                      sale.paymentMethod.substring(1)),
                              backgroundColor: payColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                  color: payColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            onTap: () => setState(() =>
                                _expandedId = isExpanded ? null : sale.id),
                          ),
                          if (isExpanded)
                            Container(
                              color: const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...sale.items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  '${item.quantity}× ${item.product.name}',
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ),
                                            Text(
                                              '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Subtotal',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                      Text(
                                          '\$${sale.subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  if (sale.discount > 0)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Discount',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600)),
                                        Text(
                                            '-\$${sale.discount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.red)),
                                      ],
                                    ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Tax (10%)',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                      Text('\$${sale.tax.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          '\$${sale.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A73E8))),
                                    ],
                                  ),
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
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
