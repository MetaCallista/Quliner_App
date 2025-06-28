import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'restaurant_form_screen.dart';
import 'restaurant_detail_screen.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => OwnerHomePageState();
}

class OwnerHomePageState extends State<OwnerHomePage> {
  final dbHelper = DatabaseHelper();
  Future<List<Restaurant>>? _restaurantsFuture;
  int? _currentUserId;

  // State untuk notifikasi atas
  bool _isBannerVisible = false;
  String _bannerMessage = '';
  Color _bannerColor = Colors.green;
  IconData _bannerIcon = Icons.check_circle;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndRestaurants();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserDataAndRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getInt('userId');
        if (_currentUserId != null) {
          refreshRestaurantList();
        }
      });
    }
  }

  void refreshRestaurantList() {
    if (_currentUserId != null) {
      setState(() {
        _restaurantsFuture = dbHelper.getRestaurantsForUser(_currentUserId!);
      });
    }
  }

  void _navigateAndRefresh(Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      refreshRestaurantList();
      // Tampilkan notifikasi sukses saat mengedit/menyimpan
      showTopBanner('Restoran berhasil diperbarui.');
    }
  }

  void showTopBanner(String message, {bool isSuccess = true}) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = message;
      _bannerColor = isSuccess ? Colors.teal : Colors.red.shade700;
      _bannerIcon = isSuccess ? Icons.check_circle : Icons.error;
      _isBannerVisible = true;
    });
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isBannerVisible = false);
      }
    });
  }

  void _deleteRestaurant(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus restoran ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteRestaurant(id);
              Navigator.of(ctx).pop();
              refreshRestaurantList();
              if (mounted) {
                showTopBanner('Restoran berhasil dihapus.', isSuccess: false);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Saya'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => refreshRestaurantList(),
            child: _currentUserId == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Restaurant>>(
                    future: _restaurantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }
                      final restaurants = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          return _buildRestaurantCard(
                              context, restaurants[index]);
                        },
                      );
                    },
                  ),
          ),
          _buildTopNotificationBanner(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined,
              size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum Ada Restoran',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + di tengah bawah\nuntuk menambah restoran pertama Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
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
            color: _bannerColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(_bannerIcon, color: Colors.white),
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

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    String operationalHours = 'Jam operasional tidak diatur';
    if (restaurant.openingTime != null && restaurant.openingTime!.isNotEmpty) {
      operationalHours =
          '${restaurant.openingTime} - ${restaurant.closingTime ?? ''}';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 5,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateAndRefresh(RestaurantDetailScreen(
          restaurantId: restaurant.id!,
          isOwnerView: true,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: restaurant.images.isNotEmpty
                      ? Image.file(File(restaurant.images.first.imagePath),
                          fit: BoxFit.cover)
                      : Container(
                          color: Colors.teal.shade100,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 50)),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8)
                      ],
                      stops: const [0.4, 1.0], // Gradient dimulai dari tengah
                    ),
                  ),
                ),
                // Nama restoran di atas gambar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateAndRefresh(
                            RestaurantFormScreen(restaurant: restaurant));
                      } else if (value == 'delete') {
                        _deleteRestaurant(restaurant.id!);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'))),
                      const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                              leading:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Hapus',
                                  style: TextStyle(color: Colors.red)))),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.description ??
                        'Tidak ada deskripsi untuk restoran ini.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                restaurant.address ?? 'Alamat tidak tersedia',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize:
                            MainAxisSize.min, // Agar tidak memakan semua ruang
                        children: [
                          Icon(Icons.access_time_filled_rounded,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(operationalHours,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade800)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
