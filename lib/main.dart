// lib/main.dart
// Entry point aplikasi Cinemate
// Urutan inisialisasi:
//   1. WidgetsFlutterBinding (wajib sebelum async di main)
//   2. flutter_dotenv (.env → API keys)
//   3. GetStorage (preferensi pengguna)
//   4. Hive (cache data lokal)
//   5. Supabase (koneksi database)
//   6. runApp → CinemateApp
// Referensi: PB-001, PB-003, PB-004

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/supabase_service.dart';
import 'app.dart';

Future<void> main() async {
  // 1. Wajib dipanggil sebelum ada operasi async (referensi modul 6)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load variabel lingkungan dari assets/.env (PB-003, R-07)
  await dotenv.load(fileName: 'assets/.env');

  // 3. Inisialisasi GetStorage (PB-004)
  await GetStorage.init();

  // 4. Inisialisasi Hive (PB-004, referensi modul 6)
  await Hive.initFlutter();

  // 5. Inisialisasi Supabase (PB-002)
  await SupabaseService.initialize();

  runApp(const CinemateApp());
}
