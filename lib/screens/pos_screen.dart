import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../providers/partner_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum ScanningMode { manual, camera, infrared }



class POSScreen extends ConsumerStatefulWidget {

  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isCartExpanded = false;
  ScanningMode _scanningMode = ScanningMode.manual;
  final MobileScannerController _scannerCtrl = MobileScannerController();
  String _externalScannerBuffer = '';
  final FocusNode _keyboardFocusNode = FocusNode();
  Timer? _debounceTimer;
  final _manualCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _keyboardFocusNode.dispose();
    _debounceTimer?.cancel();
    _manualCodeCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);

    // Filter products
    final categories = [
      'All',
      ...products.map((p) => p.category).toSet(),
    ];
    final filteredProducts = products.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;

      return Scaffold(
        appBar: AppBar(
          title: const Text('POS System'),
          actions: [
            _buildInputMethodSelector(),
            const SizedBox(width: 8),
          ],
        ),

        body: KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (_scanningMode == ScanningMode.manual) return;
            if (event is KeyDownEvent) {
              _debounceTimer?.cancel();
              if (event.logicalKey == LogicalKeyboardKey.enter || 
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                _onExternalBarcodeScanned(_externalScannerBuffer);
                _externalScannerBuffer = '';
              } else if (event.character != null) {
                _externalScannerBuffer += event.character!;
                // Debounce fallback for scanners that don't send Enter
                _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                  if (_externalScannerBuffer.isNotEmpty) {
                    _onExternalBarcodeScanned(_externalScannerBuffer);
                    _externalScannerBuffer = '';
                  }
                });
              }
            }
          },
          child: Stack(
            children: [
              // Main Product Grid / Scanning Views
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _buildGlobalInputBar(),
                        if (_scanningMode == ScanningMode.camera)
                          Expanded(
                            child: Stack(
                              children: [
                                MobileScanner(
                                  controller: _scannerCtrl,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    for (final barcode in barcodes) {
                                      if (barcode.rawValue != null) {
                                        _processScannedSku(barcode.rawValue!);
                                        HapticFeedback.lightImpact();
                                      }
                                    }
                                  },
                                ),
                                _buildScannerOverlay(),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: IconButton(
                                    icon: const Icon(Icons.flashlight_on, color: Colors.white),
                                    onPressed: () => _scannerCtrl.toggleTorch(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_scanningMode == ScanningMode.infrared)
                          Expanded(
                            child: Container(
                              color: const Color(0xFF151921),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.scanLine, size: 64, color: Color(0xFF1A73E8)),
                                        const SizedBox(height: 16),
                                        const Text('Infrared Scanner Active', 
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('Point your scanner at a barcode', 
                                            style: TextStyle(color: Colors.grey.shade400)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          _buildCategoryFilters(categories),
                          Expanded(
                            child: _buildProductGrid(filteredProducts, isMobile),
                          ),
                        ],

                        // Space for the cart bar on mobile
                        if (isMobile && cartState.items.isNotEmpty)
                          const SizedBox(height: 60),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const VerticalDivider(width: 1),
                    const Expanded(flex: 4, child: CartWidget(isMobile: false)),
                  ],
                ],
              ),

              // Expandable Cart Drawer (Mobile Only)
              if (isMobile && cartState.items.isNotEmpty)
                _buildCartDrawer(cartState),
            ],
          ),
        ),

      );
    });
  }

  Widget _buildGlobalInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _manualCodeCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          hintText: 'Search or type SKU/Barcode...',
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.plus, size: 18),
            onPressed: () {
              if (_manualCodeCtrl.text.isNotEmpty) {
                _processScannedSku(_manualCodeCtrl.text);
                _manualCodeCtrl.clear();
                setState(() => _searchQuery = '');
              }
            },
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            _processScannedSku(val);
            _manualCodeCtrl.clear();
            setState(() => _searchQuery = '');
          }
        },
      ),
    );
  }


  Widget _buildCategoryFilters(List<String> categories) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(LucideIcons.check, size: 14, color: Colors.white),
                      ),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, bool isMobile) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageSearch, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No products found', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final outOfStock = product.stock <= 0;
        return InkWell(
          onTap: outOfStock
              ? null
              : () => ref.read(cartProvider.notifier).addToCart(product),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    width: double.infinity,
                    child: Center(
                      child: Icon(
                        LucideIcons.package,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.layers, size: 10, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            outOfStock ? 'Out of stock' : 'Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 10,
                              color: outOfStock ? Colors.red : Colors.grey.shade500,
                              fontWeight: outOfStock ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartDrawer(CartState cartState) {
    // Calculate total for summary bar
    double subtotal = 0;
    for (var item in cartState.items) {
      subtotal += item.product.price * item.quantity;
    }
    final totalAtBar = subtotal * 1.1; // +10% tax approx

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      top: _isCartExpanded ? null : null, // Handled by height now
      child: GestureDetector(

        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) setState(() => _isCartExpanded = true);
          if (details.primaryDelta! > 10) setState(() => _isCartExpanded = false);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _isCartExpanded
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          height: _isCartExpanded 
              ? MediaQuery.of(context).size.height * (_scanningMode == ScanningMode.camera ? 0.5 : 1.0)
              : 60,
          child: Column(

            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Bar / Handle
              InkWell(
                onTap: () => setState(() => _isCartExpanded = !_isCartExpanded),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shoppingCart, color: Color(0xFF1A73E8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cartState.items.fold<int>(0, (sum, i) => sum + i.quantity)} Items',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Review current order',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${totalAtBar.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isCartExpanded ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isCartExpanded) ...[
                const Divider(height: 1),
                Expanded(child: CartWidget(isMobile: true)),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInputMethodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ToggleButtons(
        constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: const Color(0xFF1A73E8),
        renderBorder: false,
        isSelected: [
          _scanningMode == ScanningMode.manual,
          _scanningMode == ScanningMode.camera,
          _scanningMode == ScanningMode.infrared,
        ],
        onPressed: (index) {
          final newMode = ScanningMode.values[index];
          if (newMode == ScanningMode.camera && kIsWeb) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera scanning is only available in the APK version.')),
            );
            return;
          }
          setState(() {
            _scanningMode = newMode;
            // Removed auto-expansion of cart to avoid "annoying" interruptions
            if (_scanningMode == ScanningMode.infrared) {
              _keyboardFocusNode.requestFocus();
            }
            // Manage scanner lifecycle
            if (_scanningMode == ScanningMode.camera) {
              _scannerCtrl.start();
            } else {
              _scannerCtrl.stop();
            }
          });

        },

        children: const [
          Tooltip(message: 'Manual', child: Icon(LucideIcons.mousePointer2, size: 18)),
          Tooltip(message: 'Camera', child: Icon(LucideIcons.camera, size: 18)),
          Tooltip(message: 'Infrared Scanner', child: Icon(LucideIcons.scanLine, size: 18)),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent)),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 240, height: 240,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A73E8), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onExternalBarcodeScanned(String sku) {
    if (sku.isEmpty) return;
    _processScannedSku(sku);
  }

  void _processScannedSku(String sku) {
    final products = ref.read(productsProvider);
    try {
      final product = products.firstWhere(
        (p) => p.sku.toLowerCase() == sku.toLowerCase() || p.barcode == sku,
      );
      if (product.stock > 0) {
        ref.read(cartProvider.notifier).addToCart(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} is out of stock')),
        );
      }
    } catch (e) {
      // Not found - could be a partial SKU or different barcode
    }
  }
}

class CartWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  const CartWidget({super.key, required this.isMobile});

  @override
  ConsumerState<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends ConsumerState<CartWidget> {
  final _quickAddCtrl = TextEditingController();

  @override
  void dispose() {
    _quickAddCtrl.dispose();
    super.dispose();
  }

  void _handleQuickAdd(String sku) {
    if (sku.isEmpty) return;
    final products = ref.read(productsProvider);
    try {
      final product = products.firstWhere(
        (p) => p.sku.toLowerCase() == sku.toLowerCase() || p.barcode == sku,
      );
      if (product.stock > 0) {
        ref.read(cartProvider.notifier).addToCart(product);
        _quickAddCtrl.clear();
      }
    } catch (e) {
      // Not found
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    double subtotal = cartState.items.fold(0, (sum, i) => sum + i.product.price * i.quantity);
    double itemDiscountAmount = 0;
    for (var item in cartState.items) {
      if (item.discount != null) {
        final itemTotal = item.product.price * item.quantity;
        itemDiscountAmount += item.discount!.type == 'percentage'
            ? itemTotal * item.discount!.value / 100
            : item.discount!.value;
      }
    }

    double cartDiscountAmount = 0;
    if (cartState.cartDiscount != null) {
      final afterItems = subtotal - itemDiscountAmount;
      cartDiscountAmount = cartState.cartDiscount!.type == 'percentage'
          ? afterItems * cartState.cartDiscount!.value / 100
          : cartState.cartDiscount!.value;
    }

    final totalDiscount = itemDiscountAmount + cartDiscountAmount;
    final afterDiscount = subtotal - totalDiscount;
    final tax = afterDiscount * 0.1;
    final total = afterDiscount + tax;

    final partners = ref.watch(partnersProvider);
    final customers = partners.where((p) => p.type == 'customer').toList();
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildQuickAddRow(),
          Expanded(child: _buildItemList(cartState)),
          _buildCustomerSelect(cartState, customers),
          _buildTotalsPanel(context, cartState, subtotal, totalDiscount, tax, total),
        ],
      ),
    );
  }

  Widget _buildQuickAddRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quickAddCtrl,
              decoration: InputDecoration(
                hintText: 'Quick Add SKU...',
                prefixIcon: const Icon(LucideIcons.plus, size: 16),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (val) => _handleQuickAdd(val),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _handleQuickAdd(_quickAddCtrl.text),
            icon: const Icon(LucideIcons.arrowRight, size: 18, color: Color(0xFF1A73E8)),
          ),
        ],
      ),
    );
  }



  Widget _buildCustomerSelect(CartState cartState, List<Partner> customers) {
    final selectedCustomer = cartState.selectedCustomerId != null
        ? customers.firstWhere((c) => c.id == cartState.selectedCustomerId,
            orElse: () => Partner(id: '', name: 'Unknown', type: 'customer', email: '', phone: ''))
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(LucideIcons.user, size: 20, color: Color(0xFF1A73E8)),
        title: Text(
          selectedCustomer?.name ?? 'Walk-in Customer',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Tap to change customer', style: TextStyle(fontSize: 11)),
        trailing: IconButton(
          onPressed: () => ref.read(cartProvider.notifier).clearCart(),
          icon: const Icon(LucideIcons.rotateCcw, color: Colors.grey, size: 20),
          tooltip: 'Clear Cart',
        ),
        onTap: () => _showCustomerPicker(context, ref, customers, cartState.selectedCustomerId),
      ),
    );
  }

  void _showCustomerPicker(BuildContext context, WidgetRef ref, List<Partner> customers, String? currentId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.users),
                    title: const Text('Walk-in Customer'),
                    selected: currentId == null,
                    onTap: () {
                      ref.read(cartProvider.notifier).setSelectedCustomerId(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...customers.map((c) => ListTile(
                    leading: const Icon(LucideIcons.user),
                    title: Text(c.name),
                    subtitle: Text(c.phone ?? ''),
                    selected: currentId == c.id,

                    onTap: () {
                      ref.read(cartProvider.notifier).setSelectedCustomerId(c.id);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildItemList(CartState cartState) {
    if (cartState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shoppingBag, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Empty cart', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: cartState.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = cartState.items[i];
        return ListTile(
          dense: true,
          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('\$${item.product.price.toStringAsFixed(2)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(LucideIcons.minusCircle, () => 
                ref.read(cartProvider.notifier).updateCartQuantity(item.product.id, item.quantity - 1)),
              InkWell(
                onTap: () => _editQuantityDialog(ctx, ref, item),
                child: Container(
                  width: 44,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),

              _qtyBtn(LucideIcons.plusCircle, () => 
                ref.read(cartProvider.notifier).updateCartQuantity(item.product.id, item.quantity + 1)),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: const Color(0xFF1A73E8)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildTotalsPanel(BuildContext context, CartState cartState, double sub, double disc, double tax, double total) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _totalRow('Subtotal', '\$${sub.toStringAsFixed(2)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount', style: TextStyle(fontSize: 12)),
              TextButton.icon(
                onPressed: () => _showDiscountDialog(context, ref, cartState.cartDiscount),
                icon: const Icon(LucideIcons.tag, size: 14),
                label: Text(cartState.cartDiscount != null ? 'Edit' : 'Add', style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          if (disc > 0) _totalRow('Total Saved', '-\$${disc.toStringAsFixed(2)}', color: Colors.green),
          _totalRow('Tax (10%)', '\$${tax.toStringAsFixed(2)}'),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('\$${total.toStringAsFixed(2)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A73E8))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cartState.items.isEmpty ? null : () => _showPaymentDialog(context, total, this.ref),


              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, Discount? currentDiscount) {
    final isPercentage = currentDiscount?.type != 'fixed';
    final typeNotifier = ValueNotifier<String>(isPercentage ? 'percentage' : 'fixed');
    final valueCtrl = TextEditingController(text: currentDiscount?.value.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apply Cart Discount'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'percentage', label: Text('Percentage %')),
                      ButtonSegment(value: 'fixed', label: Text('Fixed \$')),
                    ],
                    selected: {typeNotifier.value},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        typeNotifier.value = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueCtrl,
                    decoration: InputDecoration(
                      labelText: typeNotifier.value == 'percentage' ? 'Discount %' : 'Discount \$',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              );
            }
          ),
          actions: [
            if (currentDiscount != null)
              TextButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).setCartDiscount(null);
                  Navigator.pop(context);
                },
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(valueCtrl.text) ?? 0;
                if (val > 0) {
                  ref.read(cartProvider.notifier).setCartDiscount(Discount(
                    type: typeNotifier.value,
                    value: val,
                    appliedTo: 'cart',
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, double totalAmount, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return _PaymentVerificationDialog(totalAmount: totalAmount, ref: ref);
      },
    );
  }
}

class _PaymentVerificationDialog extends StatefulWidget {
  final double totalAmount;
  final WidgetRef ref;

  const _PaymentVerificationDialog({required this.totalAmount, required this.ref});

  @override
  State<_PaymentVerificationDialog> createState() => _PaymentVerificationDialogState();
}

class _PaymentVerificationDialogState extends State<_PaymentVerificationDialog> {
  String _selectedMethod = 'cash';
  final _tenderedCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tenderedCtrl.text = widget.totalAmount.toStringAsFixed(2);
    _tenderedCtrl.addListener(() => setState(() {}));
  }

  void _handleKeypad(String key) {
    String current = _tenderedCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (key == 'back') {
      if (current.isNotEmpty) {
        _tenderedCtrl.text = current.substring(0, current.length - 1);
      }

    } else if (key == '.') {
      if (!current.contains('.')) {
        _tenderedCtrl.text = current + key;
      }
    } else {
      // If current is "0.00" or equivalent of total, might want to clear it first or just append
      // But usually, in POS, you just append.
      _tenderedCtrl.text = current + key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width < 400 ? 0.8 : 1.0;
    final tenderedStr = _tenderedCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final tenderedAmt = double.tryParse(tenderedStr) ?? 0.0;
    final changeDue = tenderedAmt - widget.totalAmount;
    final canComplete = _selectedMethod != 'cash' || tenderedAmt >= (widget.totalAmount - 0.01);

    return AlertDialog(
      title: const Text('Checkout Verification'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Total Due', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    Text(
                      '\$${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', icon: Icon(LucideIcons.banknote, size: 18), label: Text('Cash')),
                  ButtonSegment(value: 'card', icon: Icon(LucideIcons.creditCard, size: 18), label: Text('Card')),
                  ButtonSegment(value: 'digital', icon: Icon(LucideIcons.qrCode, size: 18), label: Text('Digital')),
                ],
                selected: {_selectedMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedMethod = newSelection.first;
                    if (_selectedMethod != 'cash') {
                      _tenderedCtrl.text = widget.totalAmount.toStringAsFixed(2);
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedMethod == 'cash') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tenderedCtrl,
                        readOnly: true, // Use custom keypad
                        decoration: InputDecoration(
                          labelText: 'Amount Tendered',
                          prefixIcon: const Icon(LucideIcons.dollarSign, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.xCircle, size: 20, color: Colors.grey),
                            onPressed: () => setState(() => _tenderedCtrl.text = '0'),
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                        ),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Amounts Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildQuickAmount(widget.totalAmount, isExact: true),
                    _buildQuickAmount(10.0),
                    _buildQuickAmount(20.0),
                    _buildQuickAmount(50.0),
                    _buildQuickAmount(100.0),
                    _buildQuickAmount(0, isClear: true),
                  ],
                ),
                const SizedBox(height: 16),
                // Numeric Keypad
                _buildNumericKeypad(scale),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: changeDue >= -0.01 ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: changeDue >= -0.01 ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        changeDue >= -0.01 ? 'Change Due' : 'Remaining',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: changeDue >= -0.01 ? Colors.green.shade800 : Colors.red.shade800
                        ),
                      ),
                      Text(
                        '\$${changeDue.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: changeDue >= -0.01 ? Colors.green.shade900 : Colors.red.shade900
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_selectedMethod != 'cash')
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.nfc, size: 64, color: Color(0xFF1A73E8)),
                      const SizedBox(height: 16),
                      Text('Ready for ${_selectedMethod.toUpperCase()} payment', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Awaiting external terminal...', 
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 15)),
        ),
        FilledButton.icon(
          onPressed: canComplete ? () {
            final messenger = ScaffoldMessenger.of(context);
            widget.ref.read(salesProvider.notifier).completeSale(_selectedMethod);
            Navigator.pop(context);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Sale completed successfully!'), 
                backgroundColor: Color(0xFF1A73E8),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } : null,
          icon: const Icon(LucideIcons.checkCheck, size: 18),
          label: const Text('COMPLETE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: const Color(0xFF1A73E8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],

    );
  }

  Widget _buildQuickAmount(double amount, {bool isExact = false, bool isClear = false}) {
    String label = '\$${amount.toStringAsFixed(0)}';
    if (isExact) label = 'Exact';
    if (isClear) label = 'C';

    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (isClear) {
            _tenderedCtrl.text = '0';
          } else if (isExact) {
            _tenderedCtrl.text = widget.totalAmount.toStringAsFixed(2);
          } else {
            final currentStr = _tenderedCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
            final currentAmt = double.tryParse(currentStr) ?? 0.0;
            _tenderedCtrl.text = (currentAmt + amount).toStringAsFixed(2);
          }
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isClear ? Colors.red : const Color(0xFF1A73E8),
        side: BorderSide(color: isClear ? Colors.red.shade200 : Colors.grey.shade300),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildNumericKeypad(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 1; i <= 9; i++) _keypadBtn('$i'),
          _keypadBtn('.'),
          _keypadBtn('0'),
          _keypadBtn('back', isIcon: true),
        ],
      ),
    );
  }

  Widget _keypadBtn(String label, {bool isIcon = false}) {
    return InkWell(
      onTap: () => _handleKeypad(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        alignment: Alignment.center,
        child: isIcon 
          ? const Icon(LucideIcons.delete, size: 20) 
          : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

}

void _editQuantityDialog(BuildContext context, WidgetRef ref, CartItem item) {
  final ctrl = TextEditingController(text: item.quantity.toString());
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Quantity: ${item.product.name}'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final val = int.tryParse(ctrl.text) ?? item.quantity;
            ref.read(cartProvider.notifier).updateCartQuantity(item.product.id, val);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
}



