import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'login_screen.dart'; 

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPasswordVisible = false;

  bool _isBannerVisible = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      final user = await dbHelper.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name ?? '';
          _emailController.text = user.email;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTopBanner(String message) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = message;
      _isBannerVisible = true;
    });
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isBannerVisible = false;
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      String newPassword = _passwordController.text.isNotEmpty
          ? _passwordController.text
          : _currentUser!.password;

      final updatedUser = User(
        id: _currentUser!.id,
        name: _nameController.text,
        email: _emailController.text,
        password: newPassword,
      );

      await dbHelper.updateUser(updatedUser);

      if (mounted) {
        setState(() => _isSaving = false);
        _passwordController.clear();
        FocusScope.of(context).unfocus();

        _showTopBanner('Profil berhasil diperbarui!');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentUser == null
                  ? const Center(child: Text('Gagal memuat data pengguna.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                                child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.person,
                                        size: 60, color: Colors.white))),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.person_outline)),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              enabled: false,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  filled: true),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password Baru (opsional)',
                                hintText: 'Isi untuk mengubah password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            _isSaving
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton.icon(
                                    onPressed: _saveProfile,
                                    icon: const Icon(Icons.save_alt_rounded, color: Colors.white,),
                                    label: const Text('SIMPAN PERUBAHAN'),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16)),
                                  ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.red,),
                              label: const Text('KELUAR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade700),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          _buildTopNotificationBanner(),
        ],
      ),
    );
  }

  Widget _buildTopNotificationBanner() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      top: _isBannerVisible ? MediaQuery.of(context).padding.top + 10 : -100,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _bannerMessage,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
