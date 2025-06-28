import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart'; 
import 'package:quliner_app/screens/order_success_screen.dart';
import '../providers/cart_provider.dart'; 
import '../services/database_helper.dart';

class PaymentInstructionScreen extends StatelessWidget {
  final Order order;

  const PaymentInstructionScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Widget paymentContent;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Tampilkan konten berbeda berdasarkan metode pembayaran
    switch (order.paymentMethod) {
      case 'Qris':
        paymentContent = Column(
          children: [
            const Text('Silakan pindai kode QRIS di bawah ini:',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            // Di aplikasi nyata, gambar ini didapat dari Payment Gateway
            Image.asset('assets/images/placeholder_qris.png', width: 250),
            const SizedBox(height: 20),
            Text(currencyFormatter.format(order.totalPrice),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        );
        break;
      case 'BCA':
      case 'BRI':
      case 'BNI':
      case 'Mandiri':
        paymentContent = Column(
          children: [
            Text('Silakan transfer ke Virtual Account ${order.paymentMethod}:',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Di aplikasi nyata, nomor ini unik dari Payment Gateway
                child: Text('8808 1234 5678 9012',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(currencyFormatter.format(order.totalPrice),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        );
        break;
      default: // Termasuk 'Bayar di Kasir', 'OVO', 'DANA'
        paymentContent = Column(
          children: [
            const Icon(Icons.storefront_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            Text(
                'Silakan lakukan pembayaran sebesar ${currencyFormatter.format(order.totalPrice)} di kasir.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
          ],
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              paymentContent,
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                child: const Text('Saya Sudah Bayar'),
                onPressed: () {
                  final cart =
                      Provider.of<CartProvider>(context, listen: false);
                  cart.clearCart();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const OrderSuccessScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Pilih Metode Lain'))
            ],
          ),
        ),
      ),
    );
  }
}