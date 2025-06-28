import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/database_helper.dart';
import 'cart_screen.dart';

class CustomerMenuScreen extends StatefulWidget {
  final int restaurantId;
  const CustomerMenuScreen({super.key, required this.restaurantId});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final dbHelper = DatabaseHelper();
  late Future<Restaurant> _restaurantDetails;

  // Controller untuk nomor meja dan catatan dikelola di sini
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restaurantDetails = dbHelper.getFullRestaurantDetails(widget.restaurantId);
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          restaurantId: widget.restaurantId,
          // Kirim controller ke halaman keranjang agar state tidak hilang
          tableNumberController: _tableNumberController,
          notesController: _notesController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Akses CartProvider untuk data keranjang
    final cart = Provider.of<CartProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      body: FutureBuilder<Restaurant>(
        future: _restaurantDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Gagal memuat menu.'));
          }

          final restaurant = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: restaurant.images.isNotEmpty
                      ? Image.file(
                          File(restaurant.images.first.imagePath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.teal,
                          child: const Icon(Icons.restaurant,
                              color: Colors.white, size: 80)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (restaurant.description != null &&
                          restaurant.description!.isNotEmpty)
                        Text(
                          restaurant.description!,
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              height: 1.5),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                              (restaurant.openingTime != null &&
                                      restaurant.openingTime!.isNotEmpty)
                                  ? '${restaurant.openingTime} - ${restaurant.closingTime ?? ''}'
                                  : 'Jam operasional tidak diatur',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      const Divider(height: 32),
                      Text('Pilih Menu',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
              // --- DAFTAR MENU ---
              if (restaurant.menuItems.isEmpty)
                const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('Restoran ini belum memiliki menu.'),
                ))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    8.0, 0, 8.0, 80.0), 
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = restaurant.menuItems[index];
                      final quantityInCart = cart.getQuantityInCart(item);
                      return _buildMenuItemCard(
                          item, quantityInCart, currencyFormatter, cart);
                    },
                    childCount: restaurant.menuItems.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: cart.totalItemsInCart > 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToCart,
              label: Text('Keranjang (${cart.totalItemsInCart})'),
              icon: const Icon(Icons.shopping_cart),
            )
          : null,
    );
  }

  Widget _buildMenuItemCard(
      MenuItem item, int quantity, NumberFormat formatter, CartProvider cart) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(item.description!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(formatter.format(item.price),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            quantity == 0
                ? ElevatedButton(
                    onPressed: () => cart.updateCart(item, 1),
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20)),
                    child: const Text('Tambah'),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.remove,
                                color: Colors.red, size: 20),
                            onPressed: () => cart.updateCart(item, -1)),
                        Text(quantity.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.green, size: 20),
                            onPressed: () => cart.updateCart(item, 1)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
