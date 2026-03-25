import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(salesProvider);

    // Calculate stats
    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final totalProducts = products.length;
    final totalSales = sales.length;
    final lowStockCount = products.where((p) => p.stock < 20).length;

    // Sales by day (last 7 days)
    final now = DateTime.now();
    final salesByDay = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final daySales = sales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return DateFormat('yyyy-MM-dd').format(saleDate) == dateStr;
      }).toList();

      final revenue = daySales.fold<double>(0, (sum, sale) => sum + sale.total);
      return {'date': DateFormat('MMM dd').format(date), 'revenue': revenue};
    });

    // Top selling products
    final productSalesMap = <String, Map<String, dynamic>>{};
    for (var sale in sales) {
      for (var item in sale.items) {
        final existing = productSalesMap[item.product.id];
        if (existing != null) {
          existing['quantity'] = (existing['quantity'] as int) + item.quantity;
          existing['revenue'] =
              (existing['revenue'] as double) +
              (item.product.price * item.quantity);
        } else {
          productSalesMap[item.product.id] = {
            'product': item.product,
            'quantity': item.quantity,
            'revenue': item.product.price * item.quantity,
          };
        }
      }
    }

    final topProducts = productSalesMap.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    final top5Products = topProducts.take(5).toList();

    // Category distribution
    final categoryMap = <String, int>{};
    for (var product in products) {
      categoryMap[product.category] = (categoryMap[product.category] ?? 0) + 1;
    }

    final categoryData = categoryMap.entries
        .map((e) => {'name': e.key, 'value': e.value})
        .toList();

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    // Low stock alerts
    final lowStockProducts = products.where((p) => p.stock < 20).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    final top5LowStock = lowStockProducts.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Key Metrics
              GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isMobile ? 1.0 : 2.0,
                children: [
                  _MetricCard(
                    title: 'Total Revenue',
                    value: '\$${totalRevenue.toStringAsFixed(2)}',
                    icon: LucideIcons.dollarSign,
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    title: 'Total Sales',
                    value: '$totalSales',
                    icon: LucideIcons.shoppingCart,
                    color: Colors.green,
                  ),
                  _MetricCard(
                    title: 'Products',
                    value: '$totalProducts',
                    icon: LucideIcons.package,
                    color: Colors.purple,
                  ),
                  _MetricCard(
                    title: 'Low Stock',
                    value: '$lowStockCount',
                    icon: LucideIcons.alertCircle,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Revenue Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.trendingUp, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Revenue Trend (Last 7 Days)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < salesByDay.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          salesByDay[value.toInt()]['date']
                                              as String,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  interval: 1,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: salesByDay.asMap().entries.map((entry) {
                                  return FlSpot(
                                    entry.key.toDouble(),
                                    entry.value['revenue'] as double,
                                  );
                                }).toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Top Products
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Selling Products',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (top5Products.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No sales data yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...top5Products.asMap().entries.map((entry) {
                          final item = entry.value;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            title: Text(item['product'].name),
                            subtitle: Text('${item['quantity']} sold'),
                            trailing: Text(
                              '\$${(item['revenue'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory by Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: PieChart(
                              PieChartData(
                                sections: categoryData.asMap().entries.map((
                                  entry,
                                ) {
                                  return PieChartSectionData(
                                    color: colors[entry.key % colors.length],
                                    value: (entry.value['value'] as int)
                                        .toDouble(),
                                    title: '',
                                    radius: 20,
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: isMobile ? 24 : 0,
                            width: isMobile ? 0 : 24,
                          ),
                          LayoutBuilder(
                            builder: (context, _) {
                              Widget colBlock = Column(
                                children: [
                                  ...categoryData.asMap().entries.map((
                                    entry,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: colors[entry.key % colors.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.value['name'] as String,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            '${entry.value['value']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              );
                              return isMobile ? colBlock : Expanded(child: colBlock);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Low Stock Alert
              if (top5LowStock.isNotEmpty)
                Card(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              color: Colors.orange.shade900,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Low Stock Alert',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...top5LowStock.map((product) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'SKU: ${product.sku}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${product.stock} left',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color.withOpacity(0.7), size: 22),
            ],
          ),
        ],
      ),
    );
  }
}


