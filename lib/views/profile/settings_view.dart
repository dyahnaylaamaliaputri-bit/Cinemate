// lib/views/profile/settings_view.dart
// Halaman Pengaturan Aplikasi Lanjutan: Tema, Biometrik & Manajemen Data (PB-063)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/preference_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/app_colors.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final prefCtrl = Get.isRegistered<PreferenceController>()
        ? Get.find<PreferenceController>()
        : Get.put(PreferenceController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'PENGATURAN APLIKASI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PREFERENSI TEMA APLIKASI
            _buildSectionHeader('Tampilan & Tema Aplikasi'),
            const SizedBox(height: 8),
            _buildCard([
              Obx(() {
                final currentMode = profileCtrl.themeMode.value;
                return Column(
                  children: [
                    _buildThemeOptionTile(
                      title: 'Mode Gelap (Cinematic Dark)',
                      subtitle: 'Tema gelap hemat baterai dengan nuansa bioskop',
                      icon: Icons.dark_mode_rounded,
                      value: 'dark',
                      groupValue: currentMode,
                      onTap: () => profileCtrl.setThemeMode('dark'),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildThemeOptionTile(
                      title: 'Mode Terang (Light Mode)',
                      subtitle: 'Tampilan bersih dengan kontras tinggi',
                      icon: Icons.light_mode_rounded,
                      value: 'light',
                      groupValue: currentMode,
                      onTap: () => profileCtrl.setThemeMode('light'),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildThemeOptionTile(
                      title: 'Mengikuti Sistem Perangkat',
                      subtitle: 'Otomatis berganti sesuai pengaturan HP',
                      icon: Icons.settings_brightness_rounded,
                      value: 'system',
                      groupValue: currentMode,
                      onTap: () => profileCtrl.setThemeMode('system'),
                    ),
                  ],
                );
              }),
            ]),

            const SizedBox(height: 24),

            // 2. KEAMANAN & LOGIN BIOMETRIK
            _buildSectionHeader('Keamanan & Otentikasi'),
            const SizedBox(height: 8),
            _buildCard([
              Obx(() => SwitchListTile(
                    value: profileCtrl.isBiometricEnabled.value,
                    onChanged: (val) {
                      profileCtrl.setBiometricEnabled(val);
                      Get.snackbar(
                        val ? 'Biometrik Diaktifkan' : 'Biometrik Dinonaktifkan',
                        val
                            ? 'Login dengan sidik jari / Face ID kini aktif.'
                            : 'Login biometrik telah dinonaktifkan.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.card,
                        colorText: AppColors.textPrimary,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    secondary: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.gold,
                      size: 26,
                    ),
                    title: const Text(
                      'Login Biometrik (Fingerprint / Face ID)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Gunakan sensor biometrik untuk membuka aplikasi & konfirmasi transaksi',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.surface,
                  )),
            ]),

            const SizedBox(height: 24),

            // 3. RINGKASAN PREFERENSI AKTIF
            _buildSectionHeader('Ringkasan Preferensi Aktif'),
            const SizedBox(height: 8),
            _buildCard([
              Obx(() => ListTile(
                    leading: const Icon(Icons.monetization_on_outlined,
                        color: AppColors.gold, size: 22),
                    title: const Text('Mata Uang Terpilih',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    trailing: Text(prefCtrl.selectedCurrency.value,
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  )),
              const Divider(color: AppColors.divider, height: 1),
              Obx(() => ListTile(
                    leading: const Icon(Icons.access_time_rounded,
                        color: AppColors.gold, size: 22),
                    title: const Text('Zona Waktu Jadwal',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    trailing: Text(prefCtrl.selectedTimezone.value,
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  )),
              const Divider(color: AppColors.divider, height: 1),
              Obx(() => ListTile(
                    leading: const Icon(Icons.notifications_active_outlined,
                        color: AppColors.gold, size: 22),
                    title: const Text('Notifikasi Pemesanan',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    trailing: Text(
                        prefCtrl.notifBooking.value ? 'Aktif' : 'Non-aktif',
                        style: TextStyle(
                            color: prefCtrl.notifBooking.value
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  )),
            ]),

            const SizedBox(height: 24),

            // 4. MANAJEMEN PENYIMPANAN & DATA OFFLINE
            _buildSectionHeader('Manajemen Cache & Reset'),
            const SizedBox(height: 8),
            _buildCard([
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded,
                    color: AppColors.gold, size: 22),
                title: const Text(
                  'Bersihkan Cache Film & Bioskop',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Hapus cache Hive lokal film & bioskop untuk memuat ulang data segar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                onTap: () async {
                  await profileCtrl.clearAppCache();
                  Get.snackbar(
                    'Cache Dibersihkan',
                    'Seluruh cache offline Hive berhasil dikosongkan.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.card,
                    colorText: AppColors.textPrimary,
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded,
                    color: AppColors.primary, size: 22),
                title: const Text(
                  'Reset Semua Pengaturan ke Default',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Mengembalikan mata uang, timezone, dan notifikasi ke setelan awal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                onTap: () {
                  Get.defaultDialog(
                    title: 'Konfirmasi Reset',
                    titleStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    middleText:
                        'Apakah Anda yakin ingin mengembalikan semua preferensi ke setelan bawaan pabrik?',
                    middleTextStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    backgroundColor: AppColors.card,
                    textConfirm: 'Ya, Reset',
                    textCancel: 'Batal',
                    confirmTextColor: Colors.white,
                    buttonColor: AppColors.primary,
                    cancelTextColor: AppColors.textSecondary,
                    onConfirm: () async {
                      await profileCtrl.resetAllPreferences();
                      Get.back();
                      Get.snackbar(
                        'Preferensi Direset',
                        'Semua pengaturan telah dikembalikan ke default.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.card,
                        colorText: AppColors.textPrimary,
                      );
                    },
                  );
                },
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.gold : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.gold : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
      trailing: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.gold : AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
