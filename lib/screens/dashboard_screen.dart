import 'package:flutter/material.dart';
import 'restaurant_form_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_home_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final GlobalKey<OwnerHomePageState> _homePageKey =
      GlobalKey<OwnerHomePageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OwnerHomePage(key: _homePageKey), // Halaman 0: Daftar Restoran
      const OwnerProfileScreen(), // Halaman 1: Profil
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk berpindah halaman saat ikon navbar ditekan
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // Fungsi untuk tombol FAB (+)
  void _navigateToAddRestaurant() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => const RestaurantFormScreen()),
    )
        .then((result) {
      // Setelah kembali dari form, panggil fungsi refresh di OwnerHomePage
      // untuk memuat ulang daftar restoran.
      if (result == true) {
        _homePageKey.currentState?.refreshRestaurantList();
        _homePageKey.currentState?.showTopBanner('Restoran berhasil disimpan.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        // Diberi listener agar bisa berganti halaman dengan swipe
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex == 0
          // Jika tab Beranda (index 0) aktif, tampilkan tombol Tambah
          ? FloatingActionButton(
              onPressed: _navigateToAddRestaurant,
              tooltip: 'Tambah Restoran',
              shape: const CircleBorder(),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          // Jika di halaman lain (Profil), jangan tampilkan FloatingActionButton
          : null,
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_filled),
              color: _selectedIndex == 0 ? Colors.white : Colors.grey,
              tooltip: 'Beranda',
              onPressed: () => _onItemTapped(0),
            ),
            const SizedBox(width: 40), // Ruang untuk FAB
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profil',
              color: _selectedIndex == 1 ? Colors.white : Colors.grey,
              onPressed: () => _onItemTapped(1),
            ),
          ],
        ),
      ),
    );
  }
}
