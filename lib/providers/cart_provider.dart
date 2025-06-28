import 'package:flutter/material.dart';
import '../services/database_helper.dart'; 

// Model untuk item di keranjang belanja
class CartItem {
  final MenuItem menuItem;
  int quantity;
  CartItem({required this.menuItem, this.quantity = 1});
}

// Provider kita untuk keranjang belanja
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final TextEditingController tableNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Getter untuk mengakses data dari luar
  List<CartItem> get items => _items;

  int get totalItemsInCart {
    // Menghitung total kuantitas semua item di keranjang
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    // Menghitung total harga semua item di keranjang
    return _items.fold(
        0, (sum, item) => sum + (item.menuItem.price * item.quantity));
  }

  // Fungsi untuk menambah atau mengurangi item di keranjang
  void updateCart(MenuItem item, int change) {
    // Cek apakah item sudah ada di keranjang
    for (var cartItem in _items) {
      if (cartItem.menuItem.id == item.id) {
        cartItem.quantity += change;
        // Jika kuantitas menjadi nol atau kurang, hapus item dari keranjang
        if (cartItem.quantity <= 0) {
          _items.remove(cartItem);
        }
        notifyListeners(); // Beri tahu UI untuk memperbarui tampilannya
        return;
      }
    }
    // Jika item belum ada dan merupakan penambahan baru
    if (change > 0) {
      _items.add(CartItem(menuItem: item, quantity: change));
      notifyListeners(); // Beri tahu UI untuk memperbarui tampilannya
    }
  }

  // Fungsi untuk mendapatkan kuantitas item spesifik di keranjang
  int getQuantityInCart(MenuItem item) {
    for (var cartItem in _items) {
      if (cartItem.menuItem.id == item.id) {
        return cartItem.quantity;
      }
    }
    return 0;
  }

  // Fungsi untuk mengosongkan keranjang dan form setelah pesanan berhasil
  void clearCart() {
    _items.clear();
    tableNumberController.clear();
    notesController.clear();
    notifyListeners();
  }

  // Penting untuk membersihkan controller saat tidak digunakan lagi
  @override
  void dispose() {
    tableNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
