// lib/views/booking/book_by_movie_view.dart
// Halaman Alur Pemesanan Booked by Movie (PB-019)
// Alur: Pilih Film -> Filter Bioskop yang Menayangkan -> Pilih Bioskop, Tanggal, & Jam

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_movie_controller.dart';
import '../../models/cinema_model.dart';
import '../../models/movie_model.dart';
import '../../models/showtime_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class BookByMovieView extends StatefulWidget {
  const BookByMovieView({super.key});

  @override
  State<BookByMovieView> createState() => _BookByMovieViewState();
}

class _BookByMovieViewState extends State<BookByMovieView> {
  late final BookByMovieController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<BookByMovieController>()) {
      controller = Get.put(BookByMovieController());
    } else {
      controller = Get.find<BookByMovieController>();
    }

    final args = Get.arguments;
    if (args is MovieModel) {
      controller.setMovie(args);
    } else if (args is Map && args['movie'] is MovieModel) {
      controller.setMovie(args['movie'] as MovieModel);
    } else {
      controller.initDefaultMovie();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pilih Bioskop & Jadwal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Alur Booked by Movie (PB-019)',
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

        final movie = controller.selectedMovie.value;
        if (movie == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_outlined, size: 64, color: AppColors.textDisabled),
                const SizedBox(height: 16),
                const Text('Belum ada film yang dipilih', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => _showMoviePicker(context),
                  child: const Text('Pilih Film Sekarang'),
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
                    // 1. Hero Card Film Terpilih
                    _buildSelectedMovieHero(context, movie),

                    const SizedBox(height: 16),

                    // 2. Pemilih Tanggal Horizontal (7 Hari)
                    _buildDateSelector(),

                    const SizedBox(height: 20),

                    // 3. Header Section Bioskop yang Menayangkan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bioskop yang Menayangkan',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Obx(() => Text(
                                '${controller.cinemas.length} Bioskop',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. Daftar Bioskop Accordion & Jam Tayang
                    _buildCinemasList(),
                  ],
                ),
              ),
            ),

            // 5. Sticky Bottom Bar
            _buildBottomActionBar(context),
          ],
        );
      }),
    );
  }

  // =========================================================================
  // 1. HERO CARD FILM TERPILIH
  // =========================================================================
  Widget _buildSelectedMovieHero(BuildContext context, MovieModel movie) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Backdrop Semi-Transparan
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.network(
                  movie.backdropUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Konten Info Film
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      movie.posterUrl,
                      width: 72,
                      height: 102,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 102,
                        color: AppColors.surface,
                        child: const Icon(Icons.movie, color: AppColors.textDisabled),
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                            const SizedBox(width: 3),
                            Text(
                              movie.formattedRating,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${movie.releaseYear} • ${movie.formattedDuration}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.genreString,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Tombol Ganti Film
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _showMoviePicker(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primaryLight),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ganti Film',
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                final isSelected = controller.selectedDate.value.year == date.year &&
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
                        color: isSelected ? AppColors.primaryLight : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
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
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayNumber,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          monthName,
                          style: TextStyle(
                            color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textDisabled,
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
  // 3. DAFTAR BIOSKOP ACCORDION & JAM TAYANG
  // =========================================================================
  Widget _buildCinemasList() {
    return Obx(() {
      final cinemas = controller.cinemas;
      if (cinemas.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Tidak ada bioskop yang menayangkan film ini.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cinemas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cinema = cinemas[index];
          return Obx(() {
            final isExpanded = controller.expandedCinemaId.value == cinema.id;
            final isCinemaSelected = controller.selectedCinema.value?.id == cinema.id;
            final showtimes = controller.cinemaShowtimes[cinema.id] ?? [];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCinemaSelected
                      ? AppColors.primary
                      : isExpanded
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.border,
                  width: isCinemaSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  // Cinema Header Tile (Click to Expand / Collapse)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => controller.toggleCinema(cinema.id),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.theater_comedy_rounded,
                                color: AppColors.primaryLight,
                                size: 22,
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (cinema.distanceKm != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                                          ),
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
                                Text(
                                  cinema.address,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable Showtimes Section
                  if (isExpanded) ...[
                    const Divider(color: AppColors.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: _buildCinemaShowtimesBody(cinema, showtimes),
                    ),
                  ],
                ],
              ),
            );
          });
        },
      );
    });
  }

  Widget _buildCinemaShowtimesBody(CinemaModel cinema, List<ShowtimeModel> showtimes) {
    if (controller.isLoadingShowtimes.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (showtimes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Tidak ada jadwal pada tanggal ini.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Kelompokkan showtimes berdasarkan experience / kelas studio
    final experiences = <String, List<ShowtimeModel>>{};
    for (final st in showtimes) {
      experiences.putIfAbsent(st.experience, () => []).add(st);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: experiences.entries.map((entry) {
        final expName = entry.key;
        final list = entry.value;
        final priceStr = list.isNotEmpty ? list.first.formattedPrice : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getExperienceIcon(expName), size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        expName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    priceStr,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((st) {
                  return Obx(() {
                    final isSelected = controller.selectedShowtime.value?.id == st.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => controller.selectShowtime(cinema, st),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight : AppColors.border,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
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
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${st.availableSeats} kursi',
                              style: TextStyle(
                                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textDisabled,
                                fontSize: 9,
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
      }).toList(),
    );
  }

  // =========================================================================
  // 4. STICKY BOTTOM BAR
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
        final cinema = controller.selectedCinema.value;
        final st = controller.selectedShowtime.value;
        final canProceed = controller.canProceed;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cinema != null ? cinema.name : 'Pilih Bioskop & Jam Tayang',
                    style: TextStyle(
                      color: cinema != null ? AppColors.textPrimary : AppColors.textDisabled,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    st != null ? '${st.experience} • ${st.showTime} WIB (${st.formattedPrice})' : 'Silakan pilih jadwal tayang',
                    style: TextStyle(
                      color: st != null ? AppColors.gold : AppColors.textDisabled,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppColors.primary : AppColors.card,
                foregroundColor: canProceed ? Colors.white : AppColors.textDisabled,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      _showBookingSummaryConfirmation(context, cinema!, st!);
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
  void _showMoviePicker(BuildContext context) {
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
                  'Ganti Film',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih film Now Playing untuk melihat bioskop yang menayangkannya.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ...controller.allMovies.map((m) {
                  return Obx(() {
                    final isSelected = controller.selectedMovie.value?.id == m.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          m.posterUrl,
                          width: 40,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 56,
                            color: AppColors.card,
                            child: const Icon(Icons.movie, size: 18),
                          ),
                        ),
                      ),
                      title: Text(
                        m.title,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '★ ${m.formattedRating} • ${m.genreString}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        controller.changeMovie(m);
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

  void _showBookingSummaryConfirmation(BuildContext context, CinemaModel cinema, ShowtimeModel st) {
    final movie = controller.selectedMovie.value!;
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
                        child: const Icon(Icons.movie, color: AppColors.textDisabled),
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
                          cinema.name,
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${st.hallName} (${st.experience})',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              _buildSummaryRow('Bioskop', cinema.name),
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
                  icon: const Icon(Icons.event_seat_rounded, color: Colors.white),
                  label: const Text(
                    'Konfirmasi & Pilih Kursi (PB-020)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.toNamed(
                      Routes.selectSeat,
                      arguments: {
                        'movie': movie,
                        'cinema': cinema,
                        'showtime': st,
                      },
                    );
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
