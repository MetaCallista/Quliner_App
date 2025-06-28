import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'customer_home_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Widget untuk Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
          // Konten utama
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Animasi fade-in untuk teks
                  _buildAnimatedText(
                    const Text(
                      'Terima Kasih!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    1,
                  ),
                  const SizedBox(height: 8),
                  _buildAnimatedText(
                    const Text(
                      'Pesanan Anda telah diterima dan sedang disiapkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    2,
                  ),
                  const SizedBox(height: 48),
                  _buildAnimatedText(
                    ElevatedButton(
                      onPressed: _goToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Kembali ke Daftar Restoran'),
                    ),
                    3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat animasi fade in yang berurutan
  Widget _buildAnimatedText(Widget child, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      // Delay kemunculan setiap widget
      curve: Interval(0.2 * index, 1.0, curve: Curves.easeOut),
      builder: (context, value, innerChild) {
        return Opacity(
          opacity: value,
          child: Padding(
            padding: EdgeInsets.only(top: (1 - value) * 20),
            child: innerChild,
          ),
        );
      },
      child: child,
    );
  }
}
