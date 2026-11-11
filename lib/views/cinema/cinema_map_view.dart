// lib/views/cinema/cinema_map_view.dart
// Layar Peta Bioskop Interaktif OpenStreetMap (OSM) dengan Flutter Map (PB-044, PB-045, PB-046, PB-047)
// Menampilkan posisi user, pin bioskop, filter radius, petunjuk arah, dan fallback manual.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/cinema_controller.dart';
import '../../models/cinema_model.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';
import '../../utils/app_colors.dart';

class CinemaMapView extends StatefulWidget {
  const CinemaMapView({super.key});

  @override
  State<CinemaMapView> createState() => _CinemaMapViewState();
}

class _CinemaMapViewState extends State<CinemaMapView> {
  final CinemaController _cinemaCtrl = Get.find<CinemaController>();
  final MapController _mapController = MapController();

  final List<double?> _radiusOptions = [null, 1.0, 3.0, 5.0, 10.0, 25.0];

  @override
  void initState() {
    super.initState();
    // Default fokus ke user location saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recenterToUser();
    });
  }

  void _recenterToUser() {
    _mapController.move(
      LatLng(_cinemaCtrl.userLat.value, _cinemaCtrl.userLng.value),
      13.5,
    );
  }

  void _focusToCinema(CinemaModel cinema) {
    _cinemaCtrl.selectCinemaOnMap(cinema);
    _mapController.move(
      LatLng(cinema.latitude, cinema.longitude),
      14.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. PETA INTERAKTIF FLUTTER MAP (OPENSTREETMAP) (PB-044)
          Obx(() {
            final userLatLng =
                LatLng(_cinemaCtrl.userLat.value, _cinemaCtrl.userLng.value);
            final cinemas = _cinemaCtrl.filteredCinemas;
            final selectedCinema = _cinemaCtrl.selectedCinemaOnMap.value;

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLatLng,
                initialZoom: 13.0,
                minZoom: 4.0,
                maxZoom: 18.0,
                onTap: (_, __) {
                  // Ketuk area kosong peta untuk menutup detail
                  _cinemaCtrl.selectCinemaOnMap(null);
                },
              ),
              children: [
                // Lapisan Ubin Peta OpenStreetMap (Gratis & Caching Nyaman)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cinemate.app',
                ),

                // Lapisan Marker (User Pin + Cinema Pins)
                MarkerLayer(
                  markers: [
                    // MARKER POSISI PENGGUNA (Pin Biru Glowing)
                    Marker(
                      point: userLatLng,
                      width: 54,
                      height: 54,
                      child: GestureDetector(
                        onTap: () {
                          Get.snackbar(
                            'Posisi Anda',
                            _cinemaCtrl.selectedLocationName.value,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.card,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // MARKER LOKASI BIOSKOP (Pin Merah / Emas)
                    ...cinemas.map((cinema) {
                      final isSelected = selectedCinema?.id == cinema.id;
                      return Marker(
                        point: LatLng(cinema.latitude, cinema.longitude),
                        width: isSelected ? 60 : 48,
                        height: isSelected ? 60 : 48,
                        child: GestureDetector(
                          onTap: () => _focusToCinema(cinema),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSelected ? 7 : 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.gold
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 2.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSelected
                                                ? AppColors.gold
                                                : AppColors.primary)
                                            .withValues(alpha: 0.6),
                                        blurRadius: isSelected ? 12 : 6,
                                        spreadRadius: isSelected ? 3 : 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.movie_creation_rounded,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.white,
                                    size: isSelected ? 22 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            );
          }),

          // 2. HEADER ATAS (NAVIGASI, LOKASI, & FALLBACK KOTA)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textPrimary, size: 18),
                          onPressed: () => Get.back(),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showManualCityPicker(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: AppColors.primaryLight,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'TITIK ACUAN LBS',
                                        style: TextStyle(
                                          color: AppColors.primaryLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down,
                                          color: AppColors.textSecondary,
                                          size: 14),
                                    ],
                                  ),
                                  Obx(() => Text(
                                        _cinemaCtrl.selectedLocationName.value,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Tombol Deteksi GPS
                        Obx(() {
                          final isDetecting =
                              _cinemaCtrl.isDetectingLocation.value;
                          return IconButton(
                            icon: isDetecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed_rounded,
                                    color: Colors.greenAccent, size: 22),
                            tooltip: 'Gunakan GPS Terkini',
                            onPressed: isDetecting
                                ? null
                                : () async {
                                    final ok = await _cinemaCtrl
                                        .detectCurrentLocation();
                                    if (ok) _recenterToUser();
                                  },
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. FILTER RADIUS JARAK BIOSKOP (PB-045)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Obx(() {
                      final currentRadius = _cinemaCtrl.selectedRadiusKm.value;
                      final count = _cinemaCtrl.filteredCinemas.length;

                      return Row(
                        children: [
                          ..._radiusOptions.map((radius) {
                            final isSelected = currentRadius == radius;
                            final label = radius == null
                                ? 'Semua Jarak'
                                : '${radius.toInt()} km';

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor:
                                    AppColors.card.withValues(alpha: 0.9),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                                showCheckmark: false,
                                onSelected: (_) {
                                  _cinemaCtrl.setRadius(radius);
                                },
                              ),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '$count Bioskop Ditemukan',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // 4. FLOATING ACTION CONTROLS (ZOOM & RECENTER)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  color: Colors.blueAccent,
                  onTap: _recenterToUser,
                ),
              ],
            ),
          ),

          // 5. BOTTOM CARD DETAIL BIOSKOP TERPILIH (PB-044, PB-046)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Obx(() {
              final selected = _cinemaCtrl.selectedCinemaOnMap.value;
              final list = _cinemaCtrl.filteredCinemas;

              if (selected != null) {
                return _buildSelectedCinemaCard(selected);
              }

              // Jika belum ada yang dipilih, tampilkan ringkasan bioskop terdekat
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tidak ada bioskop dalam radius ${_cinemaCtrl.selectedRadiusKm.value?.toInt()} km. Coba perluas filter radius.',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _cinemaCtrl.setRadius(null),
                        child: const Text('Reset',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                );
              }

              // Menampilkan bioskop terdekat pertama secara default
              return _buildSelectedCinemaCard(list.first,
                  isDefaultNearest: true);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSelectedCinemaCard(CinemaModel cinema,
      {bool isDefaultNearest = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefaultNearest
              ? AppColors.border
              : AppColors.gold.withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.theaters_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinema.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          cinema.city,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Jarak: ${cinema.formattedDistance}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cinema.address,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Tombol Rute Google Maps (PB-046)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text(
                    'Petunjuk Arah',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    _cinemaCtrl.openGoogleMapsRoute(cinema);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Pilih Jadwal Tayang
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.confirmation_num_rounded, size: 18),
                  label: const Text(
                    'Pesan Tiket',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Get.toNamed(Routes.bookByCinema, arguments: cinema);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dialog Pilihan Kota & Titik Lokasi Acuan Manual (PB-047)
  void _showManualCityPicker(BuildContext context) {
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
                'PILIH KOTA / TITIK ACUAN LBS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih kota Anda untuk menghitung bioskop terdekat secara offline tanpa GPS (PB-047).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: LocationService.presets.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final preset = LocationService.presets[index];
                    return Obx(() {
                      final isSelected =
                          _cinemaCtrl.selectedLocationName.value == preset.name;
                      return ListTile(
                        leading: Icon(
                          Icons.location_city_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          preset.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          preset.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryLight, size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _cinemaCtrl.setManualLocation(preset);
                          _recenterToUser();
                        },
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
