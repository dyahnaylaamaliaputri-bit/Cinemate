// lib/bindings/auth_binding.dart
// GetX Binding: lazy-load AuthController untuk halaman auth
// Referensi: PB-001

import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
