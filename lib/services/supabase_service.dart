// lib/services/supabase_service.dart
// Singleton Supabase client
// Referensi: PB-002, PB-003, NFR-004

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  /// Inisialisasi Supabase dari .env — dipanggil sekali di main()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  /// Akses langsung ke Supabase client
  SupabaseClient get client => Supabase.instance.client;
}
