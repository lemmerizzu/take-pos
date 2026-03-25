import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);

    // Calculate subtotal, item discount amount, cart discount amount, tax, and total
    double subtotal = 0;
    double itemDiscountAmount = 0;
    for (var item in cartState.items) {
      subtotal += item.product.price * item.quantity;
      if (item.discount != null) {
        final itemTotal = item.product.price * item.quantity;
        if (item.discount!.type == 'percentage') {
          itemDiscountAmount += itemTotal * item.discount!.value / 100;
        } else {
          itemDiscountAmount += item.discount!.value;
        }
      }
    }

    double cartDiscountAmount = 0;
    if (cartState.cartDiscount != null) {
      final subtotalAfterItemDiscounts = subtotal - itemDiscountAmount;
      if (cartState.cartDiscount!.type == 'percentage') {
        cartDiscountAmount =
            subtotalAfterItemDiscounts * cartState.cartDiscount!.value / 100;
      } else {
        cartDiscountAmount = cartState.cartDiscount!.value;
      }
    }

    final totalDiscount = itemDiscountAmount + cartDiscountAmount;
    final subtotalAfterDiscount = subtotal - totalDiscount;
    final tax = subtotalAfterDiscount * 0.1; // 10%
    final total = subtotalAfterDiscount + tax;

    // Filter products
    final categories = [
      'All',
      ...products.map((p) => p.category).toSet().toList(),
    ];
    final filteredProducts = products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final productListWidget = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.search),
                        hintText: 'Search products...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  childAspectRatio: isMobile ? 0.7 : 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: InkWell(
                      onTap: product.stock > 0
                          ? () => ref
                                .read(cartProvider.notifier)
                                .addToCart(product)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.package,
                                  color: Colors.grey.shade400,
                                  size: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Point of Sale'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.scanLine),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barcode scanning not implemented yet.'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: isMobile
              ? productListWidget
              : Row(
                  children: [
                    Expanded(flex: 6, child: productListWidget),
                    const VerticalDivider(width: 1),
                    const Expanded(flex: 4, child: CartWidget(isMobile: false)),
                  ],
                ),
          floatingActionButton: isMobile && cartState.items.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const CartWidget(isMobile: true),
                    );
                  },
                  icon: const Icon(LucideIcons.shoppingCart),
                  label: Text(
                    '${cartState.items.fold<int>(0, (sum, i) => sum + i.quantity)} Items = \$${total.toStringAsFixed(2)}',
                  ),
                )
              : null,
        );
      },
    );
  }
}

class CartWidget extends ConsumerWidget {
  final bool isMobile;

  const CartWidget({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    // Recalculate totals inside the consumer to ensure it updates when cartState changes
    double subtotal = 0;
    double itemDiscountAmount = 0;
    for (var item in cartState.items) {
      subtotal += item.product.price * item.quantity;
      if (item.discount != null) {
        final itemTotal = item.product.price * item.quantity;
        if (item.discount!.type == 'percentage') {
          itemDiscountAmount += itemTotal * item.discount!.value / 100;
        } else {
          itemDiscountAmount += item.discount!.value;
        }
      }
    }

    double cartDiscountAmount = 0;
    if (cartState.cartDiscount != null) {
      final subtotalAfterItemDiscounts = subtotal - itemDiscountAmount;
      if (cartState.cartDiscount!.type == 'percentage') {
        cartDiscountAmount =
            subtotalAfterItemDiscounts * cartState.cartDiscount!.value / 100;
      } else {
        cartDiscountAmount = cartState.cartDiscount!.value;
      }
    }

    final totalDiscount = itemDiscountAmount + cartDiscountAmount;
    final subtotalAfterDiscount = subtotal - totalDiscount;
    final tax = subtotalAfterDiscount * 0.1; // 10%
    final total = subtotalAfterDiscount + tax;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (cartState.items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),
        Expanded(
          child: cartState.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.shoppingCart,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cart is empty',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return ListTile(
                      title: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '\$${item.product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              LucideIcons.minusCircle,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateCartQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.plusCircle,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateCartQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Cart Totals & Checkout
        if (cartState.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('\$${subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                if (totalDiscount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(color: Colors.green),
                      ),
                      Text(
                        '-\$${totalDiscount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax (10%)'),
                    Text('\$${tax.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (isMobile) {
                        Navigator.pop(context);
                      }
                      _showPaymentDialog(context, total, ref);
                    },
                    icon: const Icon(LucideIcons.creditCard),
                    label: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Checkout', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    double totalAmount,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total to Pay: \$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(LucideIcons.dollarSign),
                title: const Text('Cash'),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  ref.read(salesProvider.notifier).completeSale('cash');
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sale completed successfully!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.creditCard),
                title: const Text('Card'),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  ref.read(salesProvider.notifier).completeSale('card');
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sale completed successfully!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.smartphone),
                title: const Text('Digital Wallet'),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  ref.read(salesProvider.notifier).completeSale('digital');
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sale completed successfully!'),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
