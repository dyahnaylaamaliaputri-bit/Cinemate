// lib/views/dashboard/dashboard_view.dart
// Halaman utama aplikasi dengan Navigasi Bawah 5 Menu (PB-011)
// Menggunakan IndexedStack agar state masing-masing tab tidak ter-reset saat berpindah

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/tickets_tab.dart';
import 'tabs/fnb_tab.dart';
import 'tabs/profile_tab.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final dashCtrl = Get.find<DashboardController>();

    final List<Widget> pages = [
      const HomeTab(),
      const TicketsTab(),
      const FnbTab(),
      ProfileTab(onLogoutRequested: () => _confirmLogout(context, authCtrl)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
            index: dashCtrl.currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Obx(() => BottomNavigationBar(
              backgroundColor: AppColors.surface,
              currentIndex: dashCtrl.currentIndex.value,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textDisabled,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              onTap: (index) {
                if (index == 4) {
                  // Menu ke-5: Logout memunculkan dialog konfirmasi tanpa mengubah tab yang sedang aktif
                  _confirmLogout(context, authCtrl);
                } else {
                  dashCtrl.changeTab(index);
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.movie_filter_outlined),
                  activeIcon: Icon(Icons.movie_filter_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number_outlined),
                  activeIcon: Icon(Icons.confirmation_number_rounded),
                  label: 'Tiket',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood_outlined),
                  activeIcon: Icon(Icons.fastfood_rounded),
                  label: 'Pesan Makanan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout_rounded),
                  activeIcon: Icon(Icons.logout_rounded),
                  label: 'Logout',
                ),
              ],
            )),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController ctrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun Cinemate?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Menutup dialog dengan Navigator.pop
              await ctrl.logout();
              if (context.mounted) {
                // Menggunakan Navigator.pushNamedAndRemoveUntil untuk membersihkan stack rute
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
