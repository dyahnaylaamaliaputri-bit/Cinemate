// lib/bindings/search_binding.dart
// Binding untuk layar pencarian universal (PB-051)

import 'package:get/get.dart';
import '../controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppSearchController>(() => AppSearchController());
  }
}
