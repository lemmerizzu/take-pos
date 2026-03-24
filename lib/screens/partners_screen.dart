import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/partner_provider.dart';

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

    final filteredPartners = partners.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (p.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesType = _filterType == 'all' || p.type == _filterType;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showPartnerDialog(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.users,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customers',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$customersCount',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.truck,
                              color: Colors.purple.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Suppliers',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$suppliersCount',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search),
                      hintText: 'Search partners...',
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
                    DropdownMenuEntry(value: 'all', label: 'All Partners'),
                    DropdownMenuEntry(value: 'customer', label: 'Customers'),
                    DropdownMenuEntry(value: 'supplier', label: 'Suppliers'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredPartners.length,
              itemBuilder: (context, index) {
                final partner = filteredPartners[index];
                final isCustomer = partner.type == 'customer';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCustomer
                                    ? Colors.blue.shade50
                                    : Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCustomer
                                    ? LucideIcons.user
                                    : LucideIcons.truck,
                                color: isCustomer
                                    ? Colors.blue.shade600
                                    : Colors.purple.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partner.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    isCustomer ? 'Customer' : 'Supplier',
                                    style: TextStyle(
                                      color: isCustomer
                                          ? Colors.blue.shade600
                                          : Colors.purple.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, size: 20),
                              onPressed: () =>
                                  _showPartnerDialog(context, partner),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _confirmDelete(context, partner),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (partner.email != null && partner.email!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.mail,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  partner.email!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (partner.phone != null && partner.phone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  partner.phone!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (partner.address != null &&
                            partner.address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  partner.address!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
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

  void _confirmDelete(BuildContext context, Partner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${partner.type == 'customer' ? 'Customer' : 'Supplier'}',
        ),
        content: Text('Are you sure you want to delete "${partner.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(partnersProvider.notifier).deletePartner(partner.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Partner deleted')));
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
    final notesCtrl = TextEditingController(text: partner?.notes);
    String type = partner?.type ?? 'customer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(partner == null ? 'Add Partner' : 'Edit Partner'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Partner Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Customer',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'customer',
                          groupValue: type,
                          onChanged: (val) => setState(() => type = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Supplier',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'supplier',
                          groupValue: type,
                          onChanged: (val) => setState(() => type = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
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
                  if (nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }

                  final newPartner = Partner(
                    id:
                        partner?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    type: type,
                    email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                    phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                    address: addressCtrl.text.isEmpty ? null : addressCtrl.text,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );

                  if (partner == null) {
                    ref.read(partnersProvider.notifier).addPartner(newPartner);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partner added')),
                    );
                  } else {
                    ref
                        .read(partnersProvider.notifier)
                        .updatePartner(partner.id, newPartner);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partner updated')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
