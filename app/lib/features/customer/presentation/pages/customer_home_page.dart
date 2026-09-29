import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/home/canteen_application_status_card.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Tambahkan SafeArea agar konten tidak tertutup status bar (jam/baterai)
    return SafeArea(
      // 2. Gunakan ListView agar halaman bisa di-scroll dan siap ditambah konten lain
      child: ListView(
        // 3. Beri jarak atas agar tidak terlalu menempel ke ujung layar
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        children: const [
          CanteenApplicationStatusCard(),
          
          // Nanti kamu bisa menambahkan widget lain di sini
          // Contoh: Banner Promo, Daftar Kantin Terdekat, dll.
        ],
      ),
    );
  }
}