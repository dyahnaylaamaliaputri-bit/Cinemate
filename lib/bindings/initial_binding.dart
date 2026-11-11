// lib/bindings/initial_binding.dart
// Binding awal: service-service singleton yang diinisialisasi sejak awal
// Referensi: PB-001, PB-003, PB-004

import 'package:get/get.dart';
import '../controllers/preference_controller.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // StorageService — singleton permanen
    Get.put<StorageService>(StorageService(), permanent: true);

    // PreferenceController — reaktif mata uang & zona waktu (PB-048, PB-049, PB-050)
    Get.put<PreferenceController>(PreferenceController(), permanent: true);

    // HttpService — singleton permanen
    Get.put<HttpService>(HttpService()..initialize(), permanent: true);

    // AuthService — singleton permanen
    Get.put<AuthService>(AuthService(), permanent: true);
  }
}
