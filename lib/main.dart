import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quliner_app/providers/cart_provider.dart';
import 'package:quliner_app/providers/user_provider.dart'; // Import UserProvider
import 'package:quliner_app/screens/splash_screen.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi FFI untuk platform desktop agar SQLite bisa berjalan
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // --- PERUBAHAN UTAMA DI SINI ---
    // Bungkus aplikasi dengan MultiProvider agar bisa menyediakan lebih dari satu state
    MultiProvider(
      providers: [
        // Menyediakan state untuk data pengguna (login, logout, dll.)
        ChangeNotifierProvider(create: (context) => UserProvider()),
        // Menyediakan state untuk keranjang belanja pengunjung
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const QulinerApp(),
    ),
  );
}

class QulinerApp extends StatelessWidget {
  const QulinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quliner',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.teal),
          titleTextStyle: TextStyle(
            color: Colors.teal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.teal, width: 2.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
