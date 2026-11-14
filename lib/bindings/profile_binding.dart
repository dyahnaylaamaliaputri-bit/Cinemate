// lib/bindings/profile_binding.dart
// Binding GetX untuk Profil Lanjutan & My Cinemate (PB-061 s.d. PB-065)

import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/preference_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PreferenceController>()) {
      Get.lazyPut<PreferenceController>(() => PreferenceController());
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController());
    }
  }
}
