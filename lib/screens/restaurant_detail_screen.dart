import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';
import 'qr_display_screen.dart';
import 'photo_viewer_screen.dart';
import 'map_view_screen.dart';
import 'owner_orders_screen.dart'; 

class RestaurantDetailScreen extends StatefulWidget {
  final int restaurantId;
  final bool isOwnerView;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    this.isOwnerView = false,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final dbHelper = DatabaseHelper();
  late Future<Restaurant> _restaurantDetails;
  String? _distance;
  Position? _currentUserPosition;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    setState(() {
      _restaurantDetails =
          dbHelper.getFullRestaurantDetails(widget.restaurantId);
      if (!widget.isOwnerView) {
        _restaurantDetails.then((restaurant) => _calculateDistance(restaurant));
      } else {
        _isLocating = false;
      }
    });
  }

  Future<void> _calculateDistance(Restaurant restaurant) async {
    if (restaurant.latitude == null || restaurant.longitude == null) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    if (mounted) setState(() => _isLocating = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _distance = 'Izin lokasi ditolak';
            _isLocating = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _distance = 'Izin lokasi diblokir';
          _isLocating = false;
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        _currentUserPosition = position;
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          restaurant.latitude!,
          restaurant.longitude!,
        );
        setState(() {
          _distance = distanceInMeters < 1000
              ? '${distanceInMeters.toStringAsFixed(0)} m'
              : '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
          _isLocating = false; // Lokasi ditemukan
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _distance = 'Gagal mendapatkan lokasi';
          _isLocating = false; // Gagal
        });
      }
    }
  }

  void _navigateToRouteMap(Restaurant restaurant) {
    if (_currentUserPosition == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Lokasi saat ini atau lokasi restoran tidak tersedia.')));
      return;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MapViewScreen(
                  startPoint: LatLng(_currentUserPosition!.latitude,
                      _currentUserPosition!.longitude),
                  endPoint:
                      LatLng(restaurant.latitude!, restaurant.longitude!),
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Restaurant>(
        future: _restaurantDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Restoran tidak ditemukan.'));
          }

          final restaurant = snapshot.data!;
          final currencyFormatter = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          final hasLocation =
              restaurant.latitude != null && restaurant.longitude != null;
          String operationalHours = 'Jam operasional tidak diatur';
          if (restaurant.openingTime != null &&
              restaurant.openingTime!.isNotEmpty) {
            operationalHours =
                '${restaurant.openingTime} - ${restaurant.closingTime ?? ''}';
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(restaurant.name),
                pinned: true,
                floating: true,
                snap: true,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (hasLocation)
                    SizedBox(height: 250, child: _buildMapView(restaurant))
                  else
                    Container(
                        height: 250,
                        color: Colors.grey[200],
                        child:
                            const Center(child: Text('Lokasi tidak diatur'))),
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(restaurant.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.access_time_outlined,
                                      operationalHours),
                                  const SizedBox(height: 6),
                                  _buildInfoRow(
                                      Icons.location_on_outlined,
                                      restaurant.address ??
                                          'Alamat tidak tersedia'),
                                  if (!widget.isOwnerView &&
                                      _distance != null) ...[
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.directions_walk,
                                        '$_distance dari Anda'),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Kolom Kanan: Tombol Aksi (Dengan Padding)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: _buildActionButtons(
                                  context, restaurant, hasLocation),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildSectionTitle('Tentang Restoran'),
                        Text(restaurant.description ?? 'Tidak ada deskripsi.',
                            style:
                                const TextStyle(height: 1.5, fontSize: 15)),
                        const SizedBox(height: 24),
                        if (restaurant.images.isNotEmpty) ...[
                          _buildSectionTitle('Galeri Foto'),
                          _buildPhotoGallery(context, restaurant.images),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionTitle('Menu'),
                        _buildMenuList(restaurant.menuItems, currencyFormatter),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapView(Restaurant restaurant) {
    return FlutterMap(
      options: MapOptions(
          initialCenter: LatLng(restaurant.latitude!, restaurant.longitude!),
          initialZoom: 16.0),
      children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        MarkerLayer(markers: [
          Marker(
              point: LatLng(restaurant.latitude!, restaurant.longitude!),
              child:
                  const Icon(Icons.location_pin, color: Colors.red, size: 45))
        ]),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Restaurant restaurant, bool hasLocation) {
    if (!widget.isOwnerView && hasLocation) {
      return _buildActionButton(Icons.route_outlined, 'Rute',
          _isLocating ? null : () => _navigateToRouteMap(restaurant));
    }
  
    if (widget.isOwnerView) {
      return Row(
        mainAxisSize: MainAxisSize.min, // Agar Row tidak memakan banyak tempat
        children: [
          _buildActionButton(
            Icons.receipt_long, // Ikon untuk pesanan
            'Pesanan',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerOrdersScreen(
                    restaurantId: restaurant.id!,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12), // Jarak antar tombol
  
          _buildActionButton(
            Icons.qr_code_2_rounded,
            'Kode QR',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QRDisplayScreen(
                  restaurantId: restaurant.id!,
                  restaurantName: restaurant.name,
                ),
              ),
            ),
          ),
        ],
      );
    }
  
    return const SizedBox.shrink();
  }

  Widget _buildPhotoGallery(
      BuildContext context, List<RestaurantImage> images) {
    final imagePaths = images.map((img) => img.imagePath).toList();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                            imagePaths: imagePaths, initialIndex: index)));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(images[index].imagePath),
                    fit: BoxFit.cover, width: 120, height: 120),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList(List<MenuItem> menuItems, NumberFormat formatter) {
    if (menuItems.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('Belum ada menu yang ditambahkan.')));
    }
    return Column(
      children: menuItems
          .map((item) => Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.description ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(formatter.format(item.price),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback? onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.teal.shade50,
              disabledBackgroundColor: Colors.grey.shade200,
              elevation: 0),
          child: onPressed == null
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ))
              : Icon(icon, color: Colors.teal, size: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
      ],
    );
  }
}