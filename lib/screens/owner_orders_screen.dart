import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quliner_app/screens/owner_order_detail_screen.dart';
import '../services/database_helper.dart';

class OwnerOrdersScreen extends StatefulWidget {
  final int restaurantId;
  const OwnerOrdersScreen({super.key, required this.restaurantId});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Fungsi untuk memuat atau memuat ulang data pesanan
  void _loadOrders() {
    setState(() {
      _ordersFuture = dbHelper.getOrdersForRestaurant(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Pesanan Masuk'),
      ),
      // RefreshIndicator memungkinkan owner melakukan pull-to-refresh
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            // Tampilkan loading indicator saat data sedang diambil
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Tampilkan pesan error jika terjadi kesalahan
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Tampilkan pesan jika tidak ada data atau data kosong
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Belum ada pesanan masuk.\nLakukan pull-to-refresh untuk memuat ulang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }

            // Jika data berhasil didapatkan, tampilkan list pesanan
            final orders = snapshot.data!;
            final currencyFormatter = NumberFormat.currency(
                locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  elevation: 3,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        order.tableNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    title: Text(
                      'Meja No: ${order.tableNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          // Format waktu agar lebih mudah dibaca
                          DateFormat('d MMM y, HH:mm')
                              .format(order.orderTimestamp),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // Tampilkan total harga
                          currencyFormatter.format(order.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: Text(
                      order.status,
                      style: TextStyle(
                        color: order.status == 'Pending'
                            ? Colors.orange.shade700
                            : (order.status == 'Selesai'
                                ? Colors.green
                                : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OwnerOrderDetailScreen(order: order),
                        ),
                      );

                      if (result == true && mounted) {
                        _loadOrders();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}