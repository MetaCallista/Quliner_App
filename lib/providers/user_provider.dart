import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadUserFromPrefs();
  }

  // Memuat sesi user saat aplikasi pertama kali dimulai
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final userEmail = prefs.getString('userEmail');

    if (userId != null && userEmail != null) {
      // Kita tidak menyimpan password, jadi kita buat objek User parsial
      _user = User(id: userId, email: userEmail, password: '');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Dipanggil saat user berhasil login
  Future<void> login(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id!);
    await prefs.setString('userEmail', user.email);
    notifyListeners();
  }

  // Dipanggil saat user logout
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
