// lib/views/booking/book_by_cinema_view.dart
// Halaman Alur Pemesanan Booked by Cinema (PB-018)
// Alur: Pilih Bioskop -> Pilih Film -> Pilih Tanggal & Jam Tayang

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_cinema_controller.dart';
import '../../models/cinema_model.dart';
import '../../models/movie_model.dart';
import '../../models/showtime_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class BookByCinemaView extends StatefulWidget {
  const BookByCinemaView({super.key});

  @override
  State<BookByCinemaView> createState() => _BookByCinemaViewState();
}

class _BookByCinemaViewState extends State<BookByCinemaView> {
  late final BookByCinemaController controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller jika belum terdaftar
    if (!Get.isRegistered<BookByCinemaController>()) {
      controller = Get.put(BookByCinemaController());
    } else {
      controller = Get.find<BookByCinemaController>();
    }

    // Tangkap argumen navigasi (bisa berupa CinemaModel, MovieModel, atau map)
    final args = Get.arguments;
    if (args is CinemaModel) {
      controller.setCinema(args);
    } else if (args is Map && args['cinema'] is CinemaModel) {
      final initialMovie =
          args['movie'] is MovieModel ? args['movie'] as MovieModel : null;
      controller.setCinema(args['cinema'] as CinemaModel,
          initialMovie: initialMovie);
    } else if (args is MovieModel ||
        (args is Map && args['movie'] is MovieModel)) {
      final movie = args is MovieModel ? args : args['movie'] as MovieModel;
      controller.initDefaultCinema(initialMovie: movie);
    } else {
      controller.initDefaultCinema();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pilih Jadwal Tayang',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Alur Booked by Cinema (PB-018)',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final cinema = controller.selectedCinema.value;
        if (cinema == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.theater_comedy_rounded,
                    size: 64, color: AppColors.textDisabled),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada bioskop yang dipilih',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () => _showCinemaPicker(context),
                  child: const Text('Pilih Bioskop Sekarang'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Kartu Header Bioskop Terpilih
                    _buildCinemaHeaderCard(context, cinema),

                    const SizedBox(height: 18),

                    // 2. Pemilih Tanggal Horizontal (7 Hari)
                    _buildDateSelector(),

                    const SizedBox(height: 20),

                    // 3. Pemilih Film di Bioskop Tersebut
                    _buildMovieSelector(),

                    const SizedBox(height: 20),

                    // 4. Jadwal Jam Tayang Berdasarkan Kelas Studio
                    _buildShowtimesSection(),
                  ],
                ),
              ),
            ),

            // 5. Sticky Bottom Bar Ringkasan & Lanjut ke Pemilihan Kursi
            _buildBottomActionBar(context),
          ],
        );
      }),
    );
  }

  // =========================================================================
  // 1. KARTU BIOSKOP TERPILIH & SWITCHER
  // =========================================================================
  Widget _buildCinemaHeaderCard(BuildContext context, CinemaModel cinema) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Icons.theater_comedy_rounded,
                color: AppColors.primaryLight,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cinema.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cinema.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          cinema.formattedDistance,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textDisabled),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        cinema.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            onPressed: () => _showCinemaPicker(context),
            child: const Text(
              'Ganti',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. PEMILIH TANGGAL HORIZONTAL (7 HARI MENDATANG)
  // =========================================================================
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'PILIH TANGGAL TAYANG',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.availableDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = controller.availableDates[index];
              return Obx(() {
                final isSelected =
                    controller.selectedDate.value.year == date.year &&
                        controller.selectedDate.value.month == date.month &&
                        controller.selectedDate.value.day == date.day;

                final dayLabel = _formatDayLabel(date, index);
                final dayNumber = date.day.toString();
                final monthName = _monthName(date.month);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => controller.changeDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 66,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayNumber,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          monthName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.textDisabled,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. PEMILIH FILM DI BIOSKOP TERSEBUT
  // =========================================================================
  Widget _buildMovieSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'PILIH FILM YANG TAYANG',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 155,
          child: Obx(() {
            final movies = controller.moviesAtCinema;
            if (movies.isEmpty) {
              return const Center(
                child: Text('Tidak ada film tayang.',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = movies[index];
                return Obx(() {
                  final isSelected =
                      controller.selectedMovie.value?.id == movie.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => controller.changeMovie(movie),
                    child: Container(
                      width: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      movie.posterUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.card,
                                        child: const Center(
                                          child: Icon(Icons.movie_outlined,
                                              color: AppColors.textDisabled),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check,
                                            size: 10, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '★ ${movie.formattedRating}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. JADWAL JAM TAYANG BERDASARKAN STUDIO
  // =========================================================================
  Widget _buildShowtimesSection() {
    return Obx(() {
      if (controller.isLoadingShowtimes.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final experiences = controller.uniqueExperiences;
      if (experiences.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Tidak ada jadwal tayang untuk tanggal ini.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PILIH KELAS STUDIO & JAM TAYANG',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ...experiences.map((exp) {
              final showtimes = controller.showtimesForExperience(exp);
              final samplePrice =
                  showtimes.isNotEmpty ? showtimes.first.formattedPrice : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Studio Header & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getExperienceIcon(exp),
                                color: AppColors.primaryLight,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              exp,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            samplePrice,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Showtime chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: showtimes.map((st) {
                        return Obx(() {
                          final isSelected =
                              controller.selectedShowtime.value?.id == st.id;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => controller.selectShowtime(st),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    st.showTime,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${st.availableSeats} kursi',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppColors.textDisabled,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  // =========================================================================
  // 5. STICKY BOTTOM BAR RINGKASAN
  // =========================================================================
  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Obx(() {
        final st = controller.selectedShowtime.value;
        final movie = controller.selectedMovie.value;
        final canProceed = controller.canProceed;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    st != null
                        ? '${st.experience} • ${st.showTime} WIB'
                        : 'Pilih Jam Tayang',
                    style: TextStyle(
                      color: st != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    st != null
                        ? st.formattedPrice
                        : 'Silakan pilih jadwal di atas',
                    style: TextStyle(
                      color:
                          st != null ? AppColors.gold : AppColors.textDisabled,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canProceed ? AppColors.primary : AppColors.card,
                foregroundColor:
                    canProceed ? Colors.white : AppColors.textDisabled,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: canProceed ? 4 : 0,
              ),
              icon: const Icon(Icons.event_seat_rounded, size: 18),
              label: const Text(
                'Pilih Kursi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: canProceed
                  ? () {
                      _showBookingSummaryConfirmation(context, st!, movie!);
                    }
                  : null,
            ),
          ],
        );
      }),
    );
  }

  // =========================================================================
  // MODAL / DIALOG HELPERS
  // =========================================================================
  void _showCinemaPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  'Ganti Bioskop',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih bioskop lain untuk melihat jadwal tayang film di lokasi tersebut.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ...controller.allCinemas.map((c) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedCinema.value?.id == c.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Icon(
                          Icons.theater_comedy_rounded,
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        c.address,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        controller.changeCinema(c);
                        Navigator.pop(ctx);
                      },
                    );
                  });
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookingSummaryConfirmation(
      BuildContext context, ShowtimeModel st, MovieModel movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.posterUrl,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 70,
                        color: AppColors.card,
                        child: const Icon(Icons.movie,
                            color: AppColors.textDisabled),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          controller.selectedCinema.value?.name ?? 'Bioskop',
                          style: const TextStyle(
                              color: AppColors.primaryLight, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${st.hallName} (${st.experience})',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              _buildSummaryRow('Tanggal Tayang', st.showDate),
              _buildSummaryRow('Jam Tayang', '${st.showTime} WIB'),
              _buildSummaryRow('Harga Tiket', st.formattedPrice),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon:
                      const Icon(Icons.event_seat_rounded, color: Colors.white),
                  label: const Text(
                    'Konfirmasi & Pilih Kursi (PB-020)',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final cinema = controller.selectedCinema.value;
                    if (cinema != null) {
                      Get.toNamed(
                        Routes.selectSeat,
                        arguments: {
                          'movie': movie,
                          'cinema': cinema,
                          'showtime': st,
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  IconData _getExperienceIcon(String exp) {
    if (exp.contains('IMAX')) return Icons.camera_indoor_rounded;
    if (exp.contains('Premiere')) return Icons.chair_rounded;
    return Icons.live_tv_rounded;
  }

  String _formatDayLabel(DateTime date, int index) {
    if (index == 0) return 'HARI INI';
    if (index == 1) return 'BESOK';
    const dayNames = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
    return dayNames[date.weekday - 1];
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }
}
