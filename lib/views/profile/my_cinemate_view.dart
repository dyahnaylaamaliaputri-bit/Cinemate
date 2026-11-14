// lib/views/profile/my_cinemate_view.dart
// Layar Personal "My Cinemate": Statistik, Badge Loyalitas, Preferensi Genre & Riwayat AI (PB-064, PB-065)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/preference_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/mood_history_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class MyCinemateView extends StatelessWidget {
  const MyCinemateView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final authCtrl = Get.find<AuthController>();
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
          'MY CINEMATE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
            onPressed: () => Get.toNamed(Routes.settings),
            tooltip: 'Pengaturan Aplikasi',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await profileCtrl.loadProfileStats();
          profileCtrl.loadMoodHistory();
        },
        color: AppColors.gold,
        backgroundColor: AppColors.card,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KARTU HEADER PROFIL & BADGE LOYALITAS AKTIF
              _buildUserLoyaltyCard(authCtrl, profileCtrl),

              const SizedBox(height: 20),

              // 2. KARTU STATISTIK PERSONAL PENONTON (PB-064)
              _buildSectionHeader('Statistik Menonton Film'),
              const SizedBox(height: 10),
              _buildStatsGrid(profileCtrl, prefCtrl),

              const SizedBox(height: 24),

              // 3. BADGE LOYALITAS & PROGRES LEVEL
              _buildSectionHeader('Tingkat Loyalitas Penonton'),
              const SizedBox(height: 10),
              _buildLoyaltyProgressCard(profileCtrl),

              const SizedBox(height: 24),

              // 4. PREFERENSI GENRE FILM FAVORIT (PB-064)
              Row(
                children: [
                  _buildSectionHeader('Preferensi Genre Favorit'),
                  const Spacer(),
                  Obx(() => Text(
                        '${profileCtrl.favoriteGenres.length} Dipilih',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih genre yang Anda sukai untuk mempersonalisasi rekomendasi film',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildGenreChips(profileCtrl),

              const SizedBox(height: 28),

              // 5. RIWAYAT HASIL PROFILING AI MOOD (PB-065)
              Row(
                children: [
                  _buildSectionHeader('Riwayat Rekomendasi AI Mood'),
                  const Spacer(),
                  Obx(() {
                    if (profileCtrl.moodHistory.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return TextButton.icon(
                      onPressed: () {
                        Get.defaultDialog(
                          title: 'Hapus Semua Riwayat',
                          titleStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          middleText:
                              'Apakah Anda yakin ingin menghapus seluruh riwayat rekomendasi AI Mood?',
                          middleTextStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          backgroundColor: AppColors.card,
                          textConfirm: 'Hapus Semua',
                          textCancel: 'Batal',
                          confirmTextColor: Colors.white,
                          buttonColor: AppColors.primary,
                          cancelTextColor: AppColors.textSecondary,
                          onConfirm: () async {
                            await profileCtrl.clearAllMoodHistory();
                            Get.back();
                          },
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: AppColors.primary, size: 16),
                      label: const Text(
                        'Hapus Semua',
                        style: TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              _buildMoodHistorySection(profileCtrl),

              const SizedBox(height: 32),
            ],
          ),
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

  Widget _buildUserLoyaltyCard(
      AuthController authCtrl, ProfileController profileCtrl) {
    return Obx(() {
      final user = authCtrl.currentUser.value;
      final name = user?.fullName.isNotEmpty == true
          ? user!.fullName
          : 'Penonton Cinemate';
      final email = user?.email ?? 'user@cinemate.id';
      final tier = profileCtrl.currentLoyalty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.card,
              tier.color.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tier.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: tier.color.withValues(alpha: 0.2),
              child: Text(
                tier.icon,
                style: const TextStyle(fontSize: 28),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tier.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: tier.color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${tier.icon} ${tier.title}',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsGrid(
      ProfileController profileCtrl, PreferenceController prefCtrl) {
    return Obx(() {
      final watched = profileCtrl.watchedCount.value;
      final hours =
          (profileCtrl.totalWatchMinutes.value / 60).toStringAsFixed(1);
      final spentFormatted =
          prefCtrl.formatPrice(profileCtrl.totalSpentIdr.value);

      return Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.movie_outlined,
              value: '$watched',
              label: 'Tiket Ditonton',
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time_rounded,
              value: '$hours Jam',
              label: 'Waktu Tonton',
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatItem(
              icon: Icons.savings_outlined,
              value: spentFormatted,
              label: 'Total Belanja',
              color: Colors.greenAccent,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyProgressCard(ProfileController profileCtrl) {
    return Obx(() {
      final tier = profileCtrl.currentLoyalty;
      final progress = profileCtrl.nextLevelProgress;
      final remaining = profileCtrl.ticketsToNextLevel;
      final nextTitle = profileCtrl.nextLevelTitle;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${tier.icon} ${tier.title}',
                  style: TextStyle(
                    color: tier.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  remaining > 0
                      ? '$remaining tiket lagi ke $nextTitle'
                      : 'Tier Tertinggi!',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(tier.color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTierPill('Bronze', '🥉', 0, profileCtrl.watchedCount.value),
                _buildTierPill('Silver', '🥈', 3, profileCtrl.watchedCount.value),
                _buildTierPill('Gold', '🥇', 6, profileCtrl.watchedCount.value),
                _buildTierPill(
                    'Platinum', '👑', 10, profileCtrl.watchedCount.value),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTierPill(
      String name, String icon, int minTickets, int currentWatched) {
    final isReached = currentWatched >= minTickets;
    return Column(
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 16,
            color: isReached ? null : Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            color: isReached ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChips(ProfileController profileCtrl) {
    return Obx(() {
      final selected = profileCtrl.favoriteGenres;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ProfileController.allAvailableGenres.map((genre) {
          final isSelected = selected.contains(genre);
          return FilterChip(
            label: Text(
              genre,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => profileCtrl.toggleFavoriteGenre(genre),
            backgroundColor: AppColors.card,
            selectedColor: AppColors.gold.withValues(alpha: 0.3),
            checkmarkColor: AppColors.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.gold : AppColors.border,
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildMoodHistorySection(ProfileController profileCtrl) {
    return Obx(() {
      final history = profileCtrl.moodHistory;

      if (history.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.psychology_outlined,
                  color: AppColors.gold, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Belum Ada Riwayat AI Mood',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gunakan fitur Rekomendasi Mood AI untuk mencari film sesuai suasana hatimu!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(Routes.moodPicker),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Coba Mood AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = history[index];
          return _buildMoodHistoryCard(item, profileCtrl);
        },
      );
    });
  }

  Widget _buildMoodHistoryCard(
      MoodHistoryModel item, ProfileController profileCtrl) {
    final dateFormatted =
        '${item.timestamp.day.toString().padLeft(2, '0')}/${item.timestamp.month.toString().padLeft(2, '0')}/${item.timestamp.year} ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.moodEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.moodTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 16),
                onPressed: () => profileCtrl.removeMoodHistoryItem(item.id),
                tooltip: 'Hapus Entri',
              ),
            ],
          ),
          if (item.movies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.movies.map((m) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_rounded,
                          color: AppColors.gold, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        m.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${m.matchPercentage}%)',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
