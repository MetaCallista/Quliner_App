import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

// Helper class untuk mengelola controller menu dinamis
class MenuItemController {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descController;

  MenuItemController()
      : nameController = TextEditingController(),
        priceController = TextEditingController(),
        descController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
  }
}

class RestaurantFormScreen extends StatefulWidget {
  final Restaurant? restaurant;
  const RestaurantFormScreen({super.key, this.restaurant});
  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  // --- KONTROLER LAMA ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  // --- KONTROLER BARU UNTUK PEMBAYARAN ---
  final TextEditingController _vaController = TextEditingController();

  // State
  final List<XFile> _newlySelectedImages = [];
  List<String> _existingImagePaths = []; 
  // --- STATE BARU UNTUK GAMBAR QRIS ---
  XFile? _qrisImage; 
  String? _existingQrisImagePath;

  final List<MenuItemController> _menuControllers = [];
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  TimeOfDay? _openingTime, _closingTime;

  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isDataLoaded = false; 

  static final LatLng _initialPosition = LatLng(-8.1164, 115.0878);

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.restaurant != null;

    if (_isEditMode) {
      _loadExistingData();
    } else {
      _isDataLoaded = true;
      _addMenuItem(); 
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);

    final fullRestaurant =
        await dbHelper.getFullRestaurantDetails(widget.restaurant!.id!);

    _nameController.text = fullRestaurant.name;
    _descController.text = fullRestaurant.description ?? '';
    _addressController.text = fullRestaurant.address ?? '';
    // --- MEMUAT DATA PEMBAYARAN LAMA ---
    _vaController.text = fullRestaurant.virtualAccountNumber ?? '';
    _existingQrisImagePath = fullRestaurant.qrisImagePath;
    
    // ... (sisa kode _loadExistingData tidak berubah)

    if (fullRestaurant.latitude != null) {
      _selectedLocation =
          LatLng(fullRestaurant.latitude!, fullRestaurant.longitude!);
    }
    if (fullRestaurant.openingTime != null &&
        fullRestaurant.openingTime!.isNotEmpty) {
      try {
        final parts = fullRestaurant.openingTime!.split(':');
        _openingTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        _openingTimeController.text = _openingTime!.format(context);
      } catch (e) {/* Abaikan jika format salah */}
    }
    if (fullRestaurant.closingTime != null &&
        fullRestaurant.closingTime!.isNotEmpty) {
      try {
        final parts = fullRestaurant.closingTime!.split(':');
        _closingTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        _closingTimeController.text = _closingTime!.format(context);
      } catch (e) {/* Abaikan jika format salah */}
    }
    for (var item in fullRestaurant.menuItems) {
      final controller = MenuItemController();
      controller.nameController.text = item.itemName;
      controller.priceController.text = item.price.toString();
      controller.descController.text = item.description ?? '';
      _menuControllers.add(controller);
    }
    if (_menuControllers.isEmpty) {
      _addMenuItem();
    }
    _existingImagePaths =
        fullRestaurant.images.map((img) => img.imagePath).toList();

    setState(() {
      _isLoading = false;
      _isDataLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _vaController.dispose(); // <-- JANGAN LUPA DISPOSE KONTROLER BARU
    for (var controller in _menuControllers) {
      controller.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU UNTUK MEMILIH GAMBAR QRIS ---
  Future<void> _pickQrisImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _qrisImage = image;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('userId');
    if (currentUserId == null) {
      // ... handle error ... 
      setState(() => _isLoading = false);
      return;
    }
    
    final appDir = await getApplicationDocumentsDirectory();

    // --- LOGIKA BARU UNTUK MENYIMPAN GAMBAR QRIS ---
    String? newQrisImagePath;
    if (_qrisImage != null) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(_qrisImage!.path)}';
      final savedImage =
          await File(_qrisImage!.path).copy('${appDir.path}/$fileName');
      newQrisImagePath = savedImage.path;
    }
    
    // ... (logika penyimpanan gambar galeri tidak berubah)
    final List<RestaurantImage> newImagesForDb = [];
    for (var imageFile in _newlySelectedImages) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
      final savedImage =
          await File(imageFile.path).copy('${appDir.path}/$fileName');
      newImagesForDb
          .add(RestaurantImage(restaurantId: 0, imagePath: savedImage.path));
    }
    
    // ... (logika penyimpanan menu tidak berubah)
    final List<MenuItem> menuItemsForDb = [];
    for (var controller in _menuControllers) {
      if (controller.nameController.text.isNotEmpty &&
          controller.priceController.text.isNotEmpty) {
        menuItemsForDb.add(MenuItem(
          restaurantId: 0,
          itemName: controller.nameController.text,
          price: int.tryParse(controller.priceController.text) ?? 0,
          description: controller.descController.text,
        ));
      }
    }

    // --- PERBARUI DATA RESTORAN DENGAN INFO PEMBAYARAN ---
    final restaurantData = Restaurant(
      id: _isEditMode ? widget.restaurant!.id : null,
      userId: currentUserId,
      name: _nameController.text,
      description: _descController.text,
      address: _addressController.text,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      openingTime: _openingTime != null ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}' : null,
      closingTime: _closingTime != null ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}' : null,
      // TAMBAHKAN DATA BARU DI SINI
      virtualAccountNumber: _vaController.text,
      qrisImagePath: newQrisImagePath ?? _existingQrisImagePath,
    );

    // ... (sisa kode _saveForm tidak berubah)
    try {
      await dbHelper.saveRestaurantTransaction(
        restaurant: restaurantData,
        menuItems: menuItemsForDb,
        newImages: newImagesForDb,
        isEditMode: _isEditMode,
      );
    } catch (e) {
        // ... handle error ...
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted && !_isLoading) {
      Navigator.of(context).pop(true);
    }
  }

  // Sisa fungsi lain (add/remove menu, select time, pick images) tidak berubah...
  void _addMenuItem() => setState(() => _menuControllers.add(MenuItemController()));
  void _removeMenuItem(int index) {
    setState(() {
      _menuControllers[index].dispose();
      _menuControllers.removeAt(index);
    });
  }
  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) setState(() => _newlySelectedImages.addAll(images));
  }
  Future<void> _selectTime(BuildContext context, {required bool isOpening}) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
          _openingTimeController.text = picked.format(context);
        } else {
          _closingTime = picked;
          _closingTimeController.text = picked.format(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return Scaffold(
          appBar: AppBar(
              title: Text(_isEditMode ? 'Memuat Data...' : 'Tambah Restoran')),
          body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Restoran' : 'Tambah Restoran'),
        actions: [
          if (!_isLoading)
            IconButton(onPressed: _saveForm, icon: const Icon(Icons.save))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informasi Dasar'),
                    _buildInfoForm(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Foto Restoran'),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    // --- TAMBAHKAN BAGIAN FORM BARU DI SINI ---
                    _buildSectionTitle('Informasi Pembayaran (Opsional)'),
                    _buildPaymentForm(),
                    const SizedBox(height: 24),
                    // -----------------------------------------
                    _buildSectionTitle('Tandai Lokasi di Peta'),
                    _buildMapView(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Daftar Menu'),
                    _buildMenuForm(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton.icon(
                        onPressed: _saveForm,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('SIMPAN SEMUA DATA'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, 
                          backgroundColor: Colors.teal, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET BARU UNTUK FORM PEMBAYARAN ---
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _vaController,
          decoration: const InputDecoration(
            labelText: 'Nomor Rekening / Virtual Account',
            hintText: 'Contoh: 1234567890',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Gambar QRIS (Untuk Pembayaran)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Menampilkan preview gambar QRIS
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _qrisImage != null
                    ? Image.file(File(_qrisImage!.path), fit: BoxFit.cover)
                    : (_existingQrisImagePath != null && _existingQrisImagePath!.isNotEmpty
                        ? Image.file(File(_existingQrisImagePath!), fit: BoxFit.cover)
                        : const Icon(Icons.qr_code_scanner, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickQrisImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Unggah QRIS'),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // Sisa helper widget tidak berubah
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }
  Widget _buildInfoForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nama Restoran'),
          validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(labelText: 'Deskripsi Singkat'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Alamat'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _openingTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Jam Buka',
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () => _selectTime(context, isOpening: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _closingTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Jam Tutup',
                  prefixIcon: Icon(Icons.timer_off_outlined),
                ),
                onTap: () => _selectTime(context, isOpening: false),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text('Pilih Gambar Baru'),
        ),
        const SizedBox(height: 4),
        Text(
          _isEditMode
              ? 'Memilih gambar baru akan menggantikan semua gambar lama.'
              : 'Anda bisa memilih lebih dari satu gambar.',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ..._existingImagePaths.map((path) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path),
                      width: 80, height: 80, fit: BoxFit.cover),
                )),
            ..._newlySelectedImages.map((file) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(file.path),
                      width: 80, height: 80, fit: BoxFit.cover),
                )),
          ],
        )
      ],
    );
  }
  Widget _buildMenuForm() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _menuControllers.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 2.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _menuControllers[index].nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Menu ${index + 1}',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeMenuItem(index),
                        ),
                      ),
                      validator: (v) {
                        if (v!.isEmpty &&
                            (_menuControllers[index]
                                    .priceController
                                    .text
                                    .isNotEmpty ||
                                _menuControllers[index]
                                    .descController
                                    .text
                                    .isNotEmpty)) {
                          return 'Nama menu tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _menuControllers[index].priceController,
                      decoration: const InputDecoration(
                          labelText: 'Harga', prefixText: 'Rp '),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty &&
                            _menuControllers[index]
                                .nameController
                                .text
                                .isNotEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _menuControllers[index].descController,
                      decoration: const InputDecoration(
                          labelText: 'Deskripsi Menu (Opsional)'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
       const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _addMenuItem,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('TAMBAH ITEM MENU'), 
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold, 
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildMapView() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedLocation ?? _initialPosition,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              setState(() {
                _selectedLocation = point;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.quliner_app',
            ),
            if (_selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation!,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}