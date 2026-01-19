import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mysoul/models/perfume.dart';
import 'package:mysoul/services/firestore_service.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  static const int costPrice = 7500;
  static const int sellingPrice = 10000;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<Perfume>>(
          stream: firestoreService.getPerfumes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No products available'),
              );
            }

            final perfumes = snapshot.data!;

            // Calculate statistics
            int totalProducts = 0;
            int totalSold = 0;
            int totalRemaining = 0;
            int totalInitial = 0;

            for (final perfume in perfumes) {
              final initialQty = perfume.initialQuantity;
              final currentQty = perfume.quantity;
              final soldForThisProduct = initialQty - currentQty;

              totalProducts++; // Count each product
              totalInitial += initialQty;
              totalRemaining += currentQty;

              if (soldForThisProduct > 0) {
                totalSold += soldForThisProduct;
              }
            }

            final totalRevenue = totalSold * sellingPrice;
            final totalProfit = totalSold * (sellingPrice - costPrice);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 📊 SUMMARY CARD
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Row for Product Counts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard(
                                icon: Icons.inventory,
                                title: 'Total Products',
                                value: '$totalProducts',
                                color: Colors.blue,
                              ),
                              _buildStatCard(
                                icon: Icons.shopping_bag,
                                title: 'Products Sold',
                                value: '$totalSold',
                                color: Colors.green,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Row for Quantity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard(
                                icon: Icons.production_quantity_limits,
                                title: 'Initial Stock',
                                value: '$totalInitial',
                                color: Colors.deepPurple,
                              ),
                              _buildStatCard(
                                icon: Icons.warehouse,
                                title: 'Remaining Stock',
                                value: '$totalRemaining',
                                color: totalRemaining <= 10 ? Colors.orange : Colors.teal,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Revenue Section
                          const Text(
                            'Revenue Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildRevenueRow(
                            'Total Items Sold:',
                            '$totalSold items',
                          ),
                          _buildRevenueRow(
                            'Total Revenue:',
                            '$totalRevenue Ks',
                            isBold: true,
                            color: Colors.green[700],
                          ),
                          _buildRevenueRow(
                            'Total Profit:',
                            '$totalProfit Ks',
                            isBold: true,
                            color: Colors.green[800],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// 📦 STOCK LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stock Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Chip(
                        label: Text('$totalProducts products'),
                        backgroundColor: Colors.yellow[100],
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 5),

                  ListView.builder(
                    shrinkWrap: true, // Important for nested ListView
                    physics: const NeverScrollableScrollPhysics(), // Disable nested scrolling
                    itemCount: perfumes.length,
                    itemBuilder: (context, index) {
                      final perfume = perfumes[index];
                      final sold = perfume.initialQuantity - perfume.quantity;
                      final percentageSold = perfume.initialQuantity > 0
                          ? ((sold / perfume.initialQuantity) * 100).toInt()
                          : 0;

                      // Stock status logic
                      Color statusColor = Colors.green;
                      IconData statusIcon = Icons.check_circle;
                      String statusText = 'In Stock';
                      String stockLevel = 'Good';

                      if (perfume.quantity <= 0) {
                        statusColor = Colors.red;
                        statusIcon = Icons.error;
                        statusText = 'Out of Stock';
                        stockLevel = 'Empty';
                      } else if (perfume.quantity <= 1) {
                        statusColor = Colors.red;
                        statusIcon = Icons.warning;
                        statusText = 'Critical';
                        stockLevel = 'Very Low';
                      } else if (perfume.quantity <= 3) {
                        statusColor = Colors.orange;
                        statusIcon = Icons.warning;
                        statusText = 'Low Stock';
                        stockLevel = 'Low';
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            perfume.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Initial: ${perfume.initialQuantity} | '
                                    'Remaining: ${perfume.quantity} | '
                                    'Sold: ${sold > 0 ? sold : 0}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              if (sold > 0)
                                Text(
                                  'Sales Rate: $percentageSold%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                stockLevel,
                                style: TextStyle(
                                  color: statusColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper widget for statistic cards
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for revenue rows
  Widget _buildRevenueRow(
      String label,
      String value, {
        bool isBold = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}