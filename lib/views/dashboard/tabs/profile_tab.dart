// lib/views/dashboard/tabs/profile_tab.dart
// Tab Profil: Informasi pengguna dan preferensi aplikasi (PB-011)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/storage_service.dart';
import '../../../utils/app_colors.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback onLogoutRequested;

  const ProfileTab({
    super.key,
    required this.onLogoutRequested,
  });

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final storage = StorageService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PROFIL PENGGUNA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Kartu Profil User
            Obx(() {
              final user = authCtrl.currentUser.value;
              final name = user?.fullName.isNotEmpty == true ? user!.fullName : 'Pengguna Cinemate';
              final email = user?.email ?? '-';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Member Cinemate',
                              style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bagian Preferensi
            _buildSectionHeader('Preferensi & Pengaturan'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingTile(
                icon: Icons.monetization_on_outlined,
                title: 'Mata Uang',
                subtitle: storage.currencyPref,
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.access_time_rounded,
                title: 'Zona Waktu',
                subtitle: storage.timezonePref,
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifikasi Tiket & Promo',
                subtitle: 'Aktif',
              ),
            ]),

            const SizedBox(height: 24),

            // Informasi Aplikasi
            _buildSectionHeader('Tentang'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Versi Aplikasi',
                subtitle: 'Cinemate v1.0.0 (Praktikum Pemrograman Mobile)',
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.cloud_done_outlined,
                title: 'Database Cloud',
                subtitle: 'Supabase PostgreSQL (Aktif)',
              ),
            ]),

            const SizedBox(height: 28),

            // Tombol Logout
            OutlinedButton.icon(
              onPressed: onLogoutRequested,
              icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
