// lib/app.dart
// GetMaterialApp — entry point aplikasi dengan GetX
// Referensi: PB-001

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'utils/app_theme.dart';

class CinemateApp extends StatelessWidget {
  const CinemateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cinemate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.fadeIn,
    );
  }
}
