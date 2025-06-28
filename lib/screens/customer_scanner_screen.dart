import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'customer_menu_screen.dart'; 

class CustomerScannerScreen extends StatefulWidget {
  const CustomerScannerScreen({super.key});

  @override
  State<CustomerScannerScreen> createState() => _CustomerScannerScreenState();
}

class _CustomerScannerScreenState extends State<CustomerScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isScanCompleted = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      try {
        final Map<String, dynamic> qrData = jsonDecode(code);
        // Validasi isi QR Code
        if (qrData['type'] == 'quliner-menu' &&
            qrData['restaurantId'] != null) {
          setState(() {
            _isScanCompleted = true; 
          });

          final int restaurantId = qrData['restaurantId'];

          _scannerController.stop();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerMenuScreen(restaurantId: restaurantId),
            ),
          );
        }
      } catch (e) {
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Kode QR di Meja')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke kode QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
