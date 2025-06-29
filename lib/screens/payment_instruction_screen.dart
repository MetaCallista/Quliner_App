// lib/screens/payment_instruction_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quliner_app/screens/order_success_screen.dart';
import '../providers/cart_provider.dart';
import '../services/database_helper.dart';

// DIUBAH MENJADI STATEFULWIDGET
class PaymentInstructionScreen extends StatefulWidget {
  final Order order;
  // TAMBAHAN: Terima juga daftar item dari keranjang
  final List<CartItem> cartItems;

  const PaymentInstructionScreen({
    super.key, 
    required this.order,
    required this.cartItems, // <-- Parameter baru
  });

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  final dbHelper = DatabaseHelper();
  late Future<Restaurant> _restaurantFuture;
  bool _isPlacingOrder = false; // State untuk loading saat bayar

  @override
  void initState() {
    super.initState();
    _restaurantFuture = dbHelper.getFullRestaurantDetails(widget.order.restaurantId);
  }

  // FUNGSI BARU: Logika yang dipindahkan dari CartScreen
  void _finalizeOrderAndPay() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // 1. SIMPAN PESANAN KE DATABASE DI SINI
      await dbHelper.insertOrder(widget.order, widget.cartItems);

      // 2. KOSONGKAN KERANJANG DI SINI
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.clearCart();

      // 3. PINDAH KE HALAMAN SUKSES
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pesanan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran'),
        // Tombol kembali di AppBar sekarang berfungsi karena kita pakai push biasa
        automaticallyImplyLeading: false, 
      ),
      body: FutureBuilder<Restaurant>(
        future: _restaurantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat detail pembayaran.'));
          }

          final restaurant = snapshot.data!;
          final currencyFormatter =
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          Widget paymentContent;

          // (Logika switch case untuk menampilkan konten pembayaran tidak berubah)
          switch (widget.order.paymentMethod) {
            case 'Qris':
              if (restaurant.qrisImagePath != null && restaurant.qrisImagePath!.isNotEmpty) {
                paymentContent = Column(
                  children: [
                    const Text('Silakan pindai kode QRIS di bawah ini:', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Image.file(File(restaurant.qrisImagePath!), width: 250, fit: BoxFit.contain),
                    const SizedBox(height: 20),
                    Text(currencyFormatter.format(widget.order.totalPrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                );
              } else {
                paymentContent = const Text('Metode pembayaran QRIS tidak tersedia untuk restoran ini.');
              }
              break;
            
            case 'BRI': 
            case 'Mandiri':
               if (restaurant.virtualAccountNumber != null && restaurant.virtualAccountNumber!.isNotEmpty) {
                paymentContent = Column(
                  children: [
                    Text('Silakan transfer ke Virtual Account ${widget.order.paymentMethod}:', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: SelectableText(restaurant.virtualAccountNumber!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2))),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.teal),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: restaurant.virtualAccountNumber!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nomor VA berhasil disalin!')),
                                );
                              },
                            ),
                          ],
                        ),
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

            default: 
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

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  paymentContent,
                  const SizedBox(height: 40),

                  // Tampilkan loading atau tombol bayar
                  _isPlacingOrder 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      // PANGGIL FUNGSI BARU DI SINI
                      onPressed: _finalizeOrderAndPay,
                      child: const Text('Saya Sudah Bayar'),
                    ),
                  const SizedBox(height: 12),
                  
                  // Tombol ini tidak akan tampil jika sedang loading
                  if (!_isPlacingOrder)
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