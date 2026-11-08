// lib/views/widgets/movie_card.dart
// Komponen kartu poster film untuk horizontal list (PB-012)

import 'package:flutter/material.dart';
import '../../models/movie_model.dart';
import '../../utils/app_colors.dart';

class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;
  final bool isUpcoming;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.isUpcoming = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image dengan Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 195,
                    width: 140,
                    color: AppColors.card,
                    child: movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.card,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),

                // Badge Rating (Now Playing) atau Tanggal Rilis (Upcoming)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUpcoming ? AppColors.info : AppColors.gold,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUpcoming
                              ? Icons.calendar_today_rounded
                              : Icons.star_rounded,
                          color: isUpcoming ? AppColors.info : AppColors.gold,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isUpcoming
                              ? movie.releaseYear
                              : movie.formattedRating,
                          style: TextStyle(
                            color: isUpcoming ? AppColors.info : AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Judul Film
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 3),

            // Genre Film
            Text(
              movie.genreString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.card,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.textDisabled,
          size: 40,
        ),
      ),
    );
  }
}
