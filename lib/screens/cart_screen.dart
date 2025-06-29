import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/database_helper.dart';
import 'payment_instruction_screen.dart'; 

class CartScreen extends StatefulWidget {
  final int restaurantId;

  final TextEditingController tableNumberController;
  final TextEditingController notesController;

  const CartScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumberController,
    required this.notesController,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  final List<String> _paymentMethods = [
    'Qris',
    'BRI',
    'Mandiri',
    'OVO',
    'DANA',
    'Bayar di Kasir'
  ];
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _paymentMethods.first; 
  }


void _placeOrder(BuildContext context) async {
  final cart = Provider.of<CartProvider>(context, listen: false);

  if (_formKey.currentState!.validate()) {
    try {
      final newOrder = Order(
        restaurantId: widget.restaurantId,
        tableNumber: widget.tableNumberController.text,
        notes: widget.notesController.text,
        paymentMethod: _selectedPaymentMethod!,
        totalPrice: cart.totalPrice,
        orderTimestamp: DateTime.now(),
        status: 'Pending',
      );
      
      await dbHelper.insertOrder(newOrder, cart.items);

      if (mounted) {
        Navigator.push( 
          context,
          MaterialPageRoute(
            builder: (_) => PaymentInstructionScreen(order: newOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pesanan: $e')),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Pesanan'),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                  'Keranjang Anda masih kosong.\nSilakan kembali untuk menambah pesanan.',
                  textAlign: TextAlign.center),
            ))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const Text('Item Pesanan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...cart.items.map((cartItem) => Card(
                              color: Colors.white,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(cartItem.menuItem.itemName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(currencyFormatter
                                              .format(cartItem.menuItem.price)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            color: Colors.red.shade700,
                                            onPressed: () => cart.updateCart(
                                                cartItem.menuItem, -1)),
                                        Text(cartItem.quantity.toString(),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline),
                                            color: Colors.green.shade700,
                                            onPressed: () => cart.updateCart(
                                                cartItem.menuItem, 1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pop(),
                          icon: const Icon(Icons.add_shopping_cart,
                              color: Colors.teal),
                          label: const Text('Tambah Item Lain'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal),
                        ),
                        const Divider(height: 32),
                        const Text('Informasi Tambahan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: widget
                              .tableNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Meja',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.table_restaurant_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nomor meja tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: widget
                              .notesController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan untuk Pesanan (Opsional)',
                            hintText: 'Contoh: tidak pedas, tanpa bawang...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit_note_outlined),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10)
                      ],
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Metode Pembayaran',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: _selectedPaymentMethod,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.teal),
                              items: _paymentMethods.map((String method) {
                                return DropdownMenuItem<String>(
                                    value: method, child: Text(method));
                              }).toList(),
                              onChanged: (newValue) => setState(
                                  () => _selectedPaymentMethod = newValue),
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran:',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600)),
                            Text(currencyFormatter.format(cart.totalPrice),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _placeOrder(context),
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('BAYAR SEKARANG',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}