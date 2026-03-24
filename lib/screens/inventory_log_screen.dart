import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/inventory_provider.dart';

class InventoryLogScreen extends ConsumerStatefulWidget {
  const InventoryLogScreen({super.key});

  @override
  ConsumerState<InventoryLogScreen> createState() => _InventoryLogScreenState();
}

class _InventoryLogScreenState extends ConsumerState<InventoryLogScreen> {
  String _searchQuery = '';
  String _filterType = 'ALL';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(inventoryProvider);

    final filteredLogs = logs.where((log) {
      final matchesSearch =
          log.documentNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          log.reason.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log.reference?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (log.supplierName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          log.items.any(
            (item) =>
                item.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item.productSku.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          );

      final matchesType = _filterType == 'ALL' || log.type == _filterType;

      return matchesSearch && matchesType;
    }).toList();

    filteredLogs.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Logs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search),
                      hintText: 'Search logs...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownMenu<String>(
                  initialSelection: _filterType,
                  onSelected: (val) {
                    if (val != null) setState(() => _filterType = val);
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'ALL', label: 'All Types'),
                    DropdownMenuEntry(value: 'IN', label: 'Stock In'),
                    DropdownMenuEntry(value: 'OUT', label: 'Stock Out'),
                    DropdownMenuEntry(value: 'REJECT', label: 'Rejected'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('No inventory logs found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      Color iconColor;
                      IconData iconData;

                      switch (log.type) {
                        case 'IN':
                          iconColor = Colors.green;
                          iconData = LucideIcons.arrowUpCircle;
                          break;
                        case 'OUT':
                          iconColor = Colors.blue;
                          iconData = LucideIcons.arrowDownCircle;
                          break;
                        case 'REJECT':
                        default:
                          iconColor = Colors.red;
                          iconData = LucideIcons.xCircle;
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Icon(iconData, color: iconColor),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.documentNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy HH:mm',
                                ).format(DateTime.parse(log.date)),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('Reason: ${log.reason}'),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey.shade50,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (log.reference != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Text(
                                        'Reference: ${log.reference}',
                                      ),
                                    ),
                                  if (log.supplierName != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Text(
                                        'Supplier: ${log.supplierName}',
                                      ),
                                    ),
                                  const Divider(),
                                  const Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...log.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.productName} (${item.productSku})',
                                            ),
                                          ),
                                          Text(
                                            '${log.type == 'IN' ? '+' : '-'}${item.quantity}',
                                            style: TextStyle(
                                              color: iconColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
