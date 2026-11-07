// lib/bindings/dashboard_binding.dart
// Binding untuk DashboardView dan sub-layar di dalamnya (PB-011)

import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
