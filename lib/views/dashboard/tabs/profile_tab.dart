// lib/views/dashboard/tabs/profile_tab.dart
// Tab Profil: Informasi pengguna, Edit Profil & Selector Preferensi Konversi (PB-011, PB-048, PB-049, PB-050, PB-062)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/preference_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/currency_helper.dart';
import '../../../utils/timezone_helper.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback onLogoutRequested;

  const ProfileTab({
    super.key,
    required this.onLogoutRequested,
  });

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final prefCtrl = Get.find<PreferenceController>();

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
            // 1. KARTU PROFIL USER & TOMBOL EDIT PROFIL (PB-062)
            Obx(() {
              final user = authCtrl.currentUser.value;
              final name = user?.fullName.isNotEmpty == true
                  ? user!.fullName
                  : 'Pengguna Cinemate';
              final email = user?.email ?? '-';
              final phone = user?.phone ?? '081234567890';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Member Aktif',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(Routes.editProfile),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side:
                                const BorderSide(color: AppColors.primaryLight),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // 2. KARTU PREVIEW CONVERTED RATES & TIME (PB-048, PB-049)
            Obx(() {
              final curr = prefCtrl.selectedCurrency.value;
              final tz = prefCtrl.selectedTimezone.value;
              final samplePrice = prefCtrl.formatPrice(50000);
              final sampleTime = prefCtrl.formatShowtime('19:30');

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language_rounded,
                            color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'PREVIEW KONVERSI AKTIF',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$curr â€¢ $tz',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Simulasi Tiket Rp 50.000:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                samplePrice,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jadwal 19:30 WIB:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sampleTime,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sumber Kurs: ${CurrencyHelper.rateSource}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // 3. PENGATURAN PREFERENSI (MATA UANG & ZONA WAKTU) (PB-050)
            _buildSectionHeader('Preferensi Wisatawan & Format'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              Obx(() {
                final curr = prefCtrl.selectedCurrency.value;
                final info = CurrencyHelper.getInfo(curr);
                return _buildInteractiveSettingTile(
                  icon: Icons.monetization_on_outlined,
                  title: 'Mata Uang',
                  subtitle:
                      '${info.flag} ${info.code} (${info.symbol}) - ${info.name}',
                  onTap: () => _showCurrencyPicker(context, prefCtrl),
                );
              }),
              const Divider(color: AppColors.divider, height: 1),
              Obx(() {
                final tz = prefCtrl.selectedTimezone.value;
                final info = TimezoneHelper.getInfo(tz);
                return _buildInteractiveSettingTile(
                  icon: Icons.access_time_rounded,
                  title: 'Zona Waktu Jadwal Tayang',
                  subtitle: '${info.code} - ${info.name}',
                  onTap: () => _showTimezonePicker(context, prefCtrl),
                );
              }),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifikasi Tiket & Promo',
                subtitle: 'Aktif',
              ),
            ]),

            const SizedBox(height: 24),

            // 4. INFORMASI APLIKASI
            _buildSectionHeader('Tentang Aplikasi'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Versi Aplikasi',
                subtitle: 'Cinemate v1.0.0 (GetX OOP)',
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.cloud_done_outlined,
                title: 'Database Cloud',
                subtitle: 'Supabase PostgreSQL (Aktif)',
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildSettingTile(
                icon: Icons.offline_pin_rounded,
                title: 'Penyimpanan Offline',
                subtitle: 'Hive NoSQL Cache',
              ),
            ]),

            const SizedBox(height: 28),

            // 5. TOMBOL LOGOUT
            OutlinedButton.icon(
              onPressed: onLogoutRequested,
              icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildInteractiveSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }

  /// Modal Selector Mata Uang Dinamis (PB-048, PB-050)
  void _showCurrencyPicker(
      BuildContext context, PreferenceController prefCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PILIH MATA UANG',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Harga tiket dan F&B akan otomatis dikonversi secara real-time (PB-048).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children:
                      CurrencyHelper.supportedCurrencies.values.map((cur) {
                    return Obx(() {
                      final isSelected =
                          prefCtrl.selectedCurrency.value == cur.code;
                      return ListTile(
                        leading: Text(cur.flag,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(
                          '${cur.code} (${cur.symbol})',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          cur.name,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryLight)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          prefCtrl.setCurrency(cur.code);
                        },
                      );
                    });
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Modal Selector Zona Waktu Jadwal Tayang (PB-049, PB-050)
  void _showTimezonePicker(
      BuildContext context, PreferenceController prefCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PILIH ZONA WAKTU JADWAL TAYANG',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jam tayang bioskop otomatis disesuaikan dengan zona waktu pilihan Anda (PB-049).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: TimezoneHelper.supportedZones.values.map((tz) {
                    return Obx(() {
                      final isSelected =
                          prefCtrl.selectedTimezone.value == tz.code;
                      return ListTile(
                        leading: const Icon(Icons.access_time_rounded,
                            color: AppColors.gold),
                        title: Text(
                          tz.code,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${tz.name} â€¢ ${tz.city}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryLight)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          prefCtrl.setTimezone(tz.code);
                        },
                      );
                    });
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
