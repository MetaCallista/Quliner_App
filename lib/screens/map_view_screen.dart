import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapViewScreen extends StatefulWidget {
  final LatLng startPoint;
  final LatLng endPoint;

  const MapViewScreen({
    super.key,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String _distance = '';
  String _duration = '';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final start = widget.startPoint;
    final end = widget.endPoint;
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        final route =
            coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

        final distanceInMeters = data['routes'][0]['distance'];
        final durationInSeconds = data['routes'][0]['duration'];

        setState(() {
          _routePoints = route;
          _distance = (distanceInMeters / 1000).toStringAsFixed(1); // km
          _duration = (durationInSeconds / 60).toStringAsFixed(0); // menit
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rute Perjalanan'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.startPoint,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              // Lapisan untuk menggambar rute
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              // Lapisan untuk penanda
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.startPoint,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Text('Anda',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        Icon(Icons.person_pin_circle,
                            color: Colors.blue, size: 35),
                      ],
                    ),
                  ),
                  Marker(
                    point: widget.endPoint,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Text('Tujuan',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        Icon(Icons.location_pin, color: Colors.red, size: 35),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Indikator loading
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Informasi jarak dan durasi
          if (!_isLoading && _routePoints.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoChip(Icons.directions_car, '$_distance km'),
                      _buildInfoChip(Icons.timer, '~$_duration menit'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
