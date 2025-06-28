import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRDisplayScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const QRDisplayScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();

  bool _isBannerVisible = false;
  String _bannerMessage = '';
  Color _bannerColor = Colors.green;
  IconData _bannerIcon = Icons.check_circle;
  Timer? _bannerTimer;
  bool _isSaving = false;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _showTopBanner(String message, {bool isSuccess = true}) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = message;
      _bannerColor = isSuccess ? Colors.teal : Colors.red.shade700;
      _bannerIcon = isSuccess ? Icons.check_circle : Icons.error;
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

  Future<void> _saveQrCode() async {
    setState(() => _isSaving = true);

    var status = await Permission.storage.request();
    if (status.isLimited) {
      status = PermissionStatus.granted;
    }

    if (status.isGranted) {
      try {
        RenderRepaintBoundary boundary =
            _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final result = await ImageGallerySaverPlus.saveImage(
          pngBytes,
          quality: 100,
          name: 'quliner_qr_${widget.restaurantName.replaceAll(' ', '_')}',
        );

        if (mounted) {
          if (result['isSuccess']) {
            _showTopBanner('QR Code berhasil disimpan ke galeri!');
          } else {
            _showTopBanner('Gagal menyimpan QR Code.', isSuccess: false);
          }
        }
      } catch (e) {
        if (mounted) {
          _showTopBanner('Terjadi kesalahan: $e', isSuccess: false);
        }
      }
    } else {
      if (mounted) {
        _showTopBanner('Izin untuk mengakses galeri ditolak.',
            isSuccess: false);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData =
        '{"type":"quliner-menu","restaurantId":${widget.restaurantId}}';

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Menu')),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.restaurantName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pindai kode ini untuk melihat menu digital',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250.0,
                        ),
                      ),
                    ),
                   const SizedBox(height: 32),
                    _isSaving
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _saveQrCode,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white, 
                            ),
                            label: const Text('Unduh ke Galeri'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, 
                              backgroundColor: Colors.teal, 
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    const Text(
                      'Anda bisa mencetak atau menyimpan screenshot kode ini untuk dipasang di meja.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Widget notifikasi
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
}
