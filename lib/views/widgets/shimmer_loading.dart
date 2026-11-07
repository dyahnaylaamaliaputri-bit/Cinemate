// lib/views/widgets/shimmer_loading.dart
// Widget efek skeleton / shimmer loading untuk poster & banner film (PB-012)

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * _anim.value, -0.3),
              end: Alignment(-0.5 + 3.0 * _anim.value, 0.3),
              colors: const [
                AppColors.card,
                AppColors.cardLight,
                AppColors.card,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton untuk banner carousel di atas
class BannerCarouselSkeleton extends StatelessWidget {
  const BannerCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerBox(
        width: double.infinity,
        height: 200,
        borderRadius: 20,
      ),
    );
  }
}

/// Skeleton horizontal list film (Now Playing / Coming Soon)
class MovieListSkeleton extends StatelessWidget {
  const MovieListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: 140, height: 195, borderRadius: 14),
            SizedBox(height: 8),
            ShimmerBox(width: 110, height: 14, borderRadius: 6),
            SizedBox(height: 6),
            ShimmerBox(width: 60, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
