import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/partner_provider.dart';

Color _avatarColor(String name) {
  final colors = [
    const Color(0xFF1A73E8), const Color(0xFF34A853), const Color(0xFFEA4335),
    const Color(0xFFFBBC04), const Color(0xFF9334EA), const Color(0xFF00ACC1),
  ];
  return colors[name.codeUnitAt(0) % colors.length];
}

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(partnersProvider);
    final customersCount = partners.where((p) => p.type == 'customer').length;
    final suppliersCount = partners.where((p) => p.type == 'supplier').length;

    final filtered = partners.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = p.name.toLowerCase().contains(q) ||
          (p.email?.toLowerCase().contains(q) ?? false) ||
          (p.phone?.toLowerCase().contains(q) ?? false);
      return matchSearch && (_filterType == 'all' || p.type == _filterType);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: 'Search partners…',
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
          // Stat row + filter chips
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _statBadge(LucideIcons.users, '$customersCount Customers',
                    const Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                _statBadge(LucideIcons.truck, '$suppliersCount Suppliers',
                    const Color(0xFF34A853)),
                const Spacer(),
                _filterChip('All', 'all'),
                const SizedBox(width: 4),
                _filterChip('Cust.', 'customer'),
                const SizedBox(width: 4),
                _filterChip('Supp.', 'supplier'),
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
                        Icon(LucideIcons.users,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No partners found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final isCustomer = p.type == 'customer';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _avatarColor(p.name),
                          child: Text(p.name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          [if (p.email != null) p.email!, if (p.phone != null) p.phone!].join(' · '),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Chip(
                          label: Text(isCustomer ? 'Customer' : 'Supplier'),
                          backgroundColor: isCustomer
                              ? const Color(0xFFE8F0FE)
                              : const Color(0xFFE6F4EA),
                          labelStyle: TextStyle(
                            color: isCustomer
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFF34A853),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _showPartnerDialog(context, p),
                        onLongPress: () => _confirmDelete(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartnerDialog(context, null),
        tooltip: 'Add Partner',
        child: const Icon(LucideIcons.plus),
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

  Widget _filterChip(String label, String value) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A73E8) : Colors.grey.shade200,
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

  void _confirmDelete(BuildContext context, Partner partner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Delete "${partner.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(partnersProvider.notifier).deletePartner(partner.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partner deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPartnerDialog(BuildContext context, Partner? partner) {
    final nameCtrl = TextEditingController(text: partner?.name);
    final emailCtrl = TextEditingController(text: partner?.email);
    final phoneCtrl = TextEditingController(text: partner?.phone);
    final addressCtrl = TextEditingController(text: partner?.address);
    String type = partner?.type ?? 'customer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(partner == null ? 'Add Partner' : 'Edit Partner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(nameCtrl, 'Name *'),
                _field(emailCtrl, 'Email', type: TextInputType.emailAddress),
                _field(phoneCtrl, 'Phone', type: TextInputType.phone),
                _field(addressCtrl, 'Address'),
                const SizedBox(height: 4),
                const Text('Type',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'customer', label: Text('Customer')),
                    ButtonSegment(value: 'supplier', label: Text('Supplier')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setS(() => type = v.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')));
                  return;
                }
                final p = Partner(
                  id: partner?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  type: type,
                  email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                  phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  address: addressCtrl.text.isEmpty ? null : addressCtrl.text,
                );
                final notifier = ref.read(partnersProvider.notifier);
                partner == null
                    ? notifier.addPartner(p)
                    : notifier.updatePartner(partner.id, p);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(partner == null
                        ? 'Partner added'
                        : 'Partner updated')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
