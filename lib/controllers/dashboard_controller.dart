// lib/controllers/dashboard_controller.dart
// State management untuk navigasi dashboard (PB-011)

import 'package:get/get.dart';
import 'tickets_controller.dart';

class DashboardController extends GetxController {
  /// Indeks tab yang sedang aktif (0: Dashboard, 1: Tiket, 2: Pesan Makanan, 3: Profil)
  final currentIndex = 0.obs;

  /// Mengubah tab yang aktif (hanya untuk indeks 0 s.d. 3)
  void changeTab(int index) {
    if (index >= 0 && index < 4) {
      currentIndex.value = index;
      if (index == 1 && Get.isRegistered<TicketsController>()) {
        Get.find<TicketsController>().loadTickets(forceRefresh: false);
      }
    }
  }
}
