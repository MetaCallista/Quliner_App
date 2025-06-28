import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';
import 'restaurant_detail_screen.dart';
import 'customer_scanner_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final dbHelper = DatabaseHelper();
  Future<List<Restaurant>>? _restaurantsFuture;
  Position? _currentUserPosition;

  // State untuk mengganti tampilan
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _refreshRestaurantList();
    _determinePosition();
  }

  void _refreshRestaurantList() {
    setState(() {
      _restaurantsFuture = dbHelper.getAllRestaurants();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentUserPosition = position);
    } catch (e) {
      // Gagal mendapatkan lokasi
    }
  }

  void _navigateToScanner() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CustomerScannerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMapView ? 'Peta Kuliner' : 'Quliner'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Belum ada restoran yang didaftarkan oleh pemilik usaha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }
          final restaurants = snapshot.data!;
          // Tampilan berubah sesuai state
          if (_isMapView) {
            return _buildMapView(restaurants);
          } else {
            return _buildListView(restaurants);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: !_isMapView
          ? FloatingActionButton(
              onPressed: _navigateToScanner,
              tooltip: 'Pindai QR',
              shape: const CircleBorder(),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white,),
              elevation: 2.0,
            )
          : null, 
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.teal,
        notchMargin: 8.0,
        height: 60.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home_filled,
                  color: !_isMapView ? Colors.white : Colors.grey),
              tooltip: 'Beranda',
              onPressed: () => setState(() => _isMapView = false),
            ),

            SizedBox(width: _isMapView ? 0 : 40),
            IconButton(
              icon: Icon(Icons.map_outlined,
                  color: _isMapView ? Colors.white : Colors.grey),
              tooltip: 'Tampilan Peta',
              onPressed: () => setState(() => _isMapView = true),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Tampilan Daftar
  Widget _buildListView(List<Restaurant> restaurants) {
    return RefreshIndicator(
      onRefresh: () async => _refreshRestaurantList(),
      child: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selamat Datang!",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("Temukan kuliner menarik di sekitarmu.",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          ...restaurants
              .map((restaurant) => _buildRestaurantCard(context, restaurant))
              .toList(),
        ],
      ),
    );
  }

  // Widget baru untuk Tampilan Peta
  Widget _buildMapView(List<Restaurant> restaurants) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _currentUserPosition != null
            ? LatLng(
                _currentUserPosition!.latitude, _currentUserPosition!.longitude)
            : LatLng(-8.1164, 115.0878), // Default ke Singaraja
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.quliner_app',
        ),
        MarkerLayer(
          markers: restaurants
              .where((r) => r.latitude != null && r.longitude != null)
              .map((restaurant) {
            return Marker(
                point: LatLng(restaurant.latitude!, restaurant.longitude!),
                width: 100,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                                restaurantId: restaurant.id!)));
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ]),
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.location_pin,
                          color: Colors.red, size: 35),
                    ],
                  ),
                ));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    String operationalHours = 'Jam operasional tidak diatur';
    if (restaurant.openingTime != null &&
        restaurant.openingTime!.isNotEmpty &&
        restaurant.closingTime != null &&
        restaurant.closingTime!.isNotEmpty) {
      operationalHours =
          '${restaurant.openingTime} - ${restaurant.closingTime}';
    }

    String? distanceText;
    if (_currentUserPosition != null &&
        restaurant.latitude != null &&
        restaurant.longitude != null) {
      double distanceInMeters = Geolocator.distanceBetween(
          _currentUserPosition!.latitude,
          _currentUserPosition!.longitude,
          restaurant.latitude!,
          restaurant.longitude!);
      distanceText = distanceInMeters < 1000
          ? '${distanceInMeters.toStringAsFixed(0)} m'
          : '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      RestaurantDetailScreen(restaurantId: restaurant.id!)));
        },
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
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    restaurant.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              restaurant.address ?? 'Alamat tidak tersedia',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.teal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.access_time_filled_rounded,
                            size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(operationalHours,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                      if (distanceText != null)
                        Row(children: [
                          Icon(Icons.directions_walk_rounded,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Text(distanceText,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
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
