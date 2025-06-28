import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class OwnerOrderDetailScreen extends StatefulWidget {
  final Order order;

  const OwnerOrderDetailScreen({super.key, required this.order});

  @override
  State<OwnerOrderDetailScreen> createState() => _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends State<OwnerOrderDetailScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<OrderItem>> _orderItemsFuture;
  late Order _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _orderItemsFuture = dbHelper.getOrderItems(_currentOrder.id!);
  }

  void _updateStatusAndGoBack(String newStatus) async {
    await dbHelper.updateOrderStatus(_currentOrder.id!, newStatus);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan Meja #${_currentOrder.tableNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Info Utama Pesanan ---
            _buildSectionTitle('Informasi Pesanan'),
            Card(
              color: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.confirmation_number_outlined, 'ID Pesanan', '#${_currentOrder.id}'),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Waktu Pesan', DateFormat('d MMM y, HH:mm').format(_currentOrder.orderTimestamp)),
                    _buildInfoRow(Icons.payment_outlined, 'Pembayaran', _currentOrder.paymentMethod),
                    _buildInfoRow(Icons.speaker_notes_outlined, 'Catatan', _currentOrder.notes ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Bagian Daftar Item yang Dipesan ---
            _buildSectionTitle('Item yang Dipesan'),
            FutureBuilder<List<OrderItem>>(
              future: _orderItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Tidak ada item dalam pesanan ini.');
                }
                final items = snapshot.data!;
                return Card(
                  color: Colors.white,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(), // Agar tidak bisa di-scroll di dalam scroll
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.quantity} x ${currencyFormatter.format(item.itemPrice)}'),
                        trailing: Text(
                          currencyFormatter.format(item.quantity * item.itemPrice),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // --- Bagian Total & Status ---
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormatter.format(_currentOrder.totalPrice),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Saat Ini', style: TextStyle(fontSize: 16)),
                        Text(
                          _currentOrder.status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _currentOrder.status == 'Pending' ? Colors.orange.shade700 : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Tombol Aksi untuk Owner ---
            if (_currentOrder.status == 'Pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                      label: const Text('Batalkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _updateStatusAndGoBack('Dibatalkan'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('Selesaikan'),
                       style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _updateStatusAndGoBack('Selesai'),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat baris info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 2,
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}