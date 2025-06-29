import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quliner_app/screens/order_success_screen.dart';
import '../providers/cart_provider.dart';
import '../services/database_helper.dart';

class PaymentInstructionScreen extends StatefulWidget {
  final Order order;
  const PaymentInstructionScreen({super.key, required this.order});

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  final dbHelper = DatabaseHelper();
  // Future untuk menampung data restoran yang akan diambil dari DB
  late Future<Restaurant> _restaurantFuture;

  @override
  void initState() {
    super.initState();
    // Saat halaman dimuat, langsung ambil detail restoran berdasarkan ID
    _restaurantFuture = dbHelper.getFullRestaurantDetails(widget.order.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      // Gunakan FutureBuilder untuk menampilkan data yang masih dimuat
      body: FutureBuilder<Restaurant>(
        future: _restaurantFuture,
        builder: (context, snapshot) {
          // Tampilkan loading jika data restoran belum siap
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Tampilkan error jika gagal memuat data restoran
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat detail pembayaran.'));
          }

          // Jika berhasil, kita punya data restoran yang lengkap
          final restaurant = snapshot.data!;
          final currencyFormatter =
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          Widget paymentContent;

          // Tampilkan konten berbeda berdasarkan metode pembayaran
          switch (widget.order.paymentMethod) {
            case 'Qris':
            case 'OVO':
            case 'DANA':
              // Cek apakah owner sudah mengunggah gambar QRIS
              if (restaurant.qrisImagePath != null && restaurant.qrisImagePath!.isNotEmpty) {
                paymentContent = Column(
                  children: [
                    const Text('Silakan pindai kode QRIS di bawah ini:', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    // Tampilkan gambar QRIS dari file yang disimpan
                    Image.file(File(restaurant.qrisImagePath!), width: 250, fit: BoxFit.contain),
                    const SizedBox(height: 20),
                    Text(currencyFormatter.format(widget.order.totalPrice),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                );
              } else {
                paymentContent = const Text('Metode pembayaran QRIS tidak tersedia untuk restoran ini.');
              }
              break;
            
            case 'BRI':
            case 'Mandiri':
              // Cek apakah owner sudah memasukkan nomor VA
               if (restaurant.virtualAccountNumber != null && restaurant.virtualAccountNumber!.isNotEmpty) {
                paymentContent = Column(
                  children: [
                    Text('Silakan transfer ke Virtual Account ${widget.order.paymentMethod}:', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        // Tampilkan nomor VA dari database
                        child: SelectableText(restaurant.virtualAccountNumber!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(currencyFormatter.format(widget.order.totalPrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                );
               } else {
                 paymentContent = Text('Metode pembayaran ${widget.order.paymentMethod} tidak tersedia untuk restoran ini.');
               }
              break;

            default: //'Bayar di Kasir'
              paymentContent = Column(
                  children: [
                      const Icon(Icons.storefront_outlined, size: 80, color: Colors.teal),
                      const SizedBox(height: 20),
                      Text(
                        'Silakan lakukan pembayaran sebesar ${currencyFormatter.format(widget.order.totalPrice)} di kasir.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18)
                      ),
                  ],
              );
          }

          // Tampilan utama halaman
          return Padding(
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
                      final cart = Provider.of<CartProvider>(context, listen: false);
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
          );
        },
      ),
    );
  }
}