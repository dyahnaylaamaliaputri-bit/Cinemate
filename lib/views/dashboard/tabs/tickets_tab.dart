// lib/views/dashboard/tabs/tickets_tab.dart
// Tab Tiket: Daftar tiket aktif, riwayat pemesanan, & akses offline (PB-023 s.d. PB-025)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/tickets_controller.dart';
import '../../../models/ticket_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TicketsController _controller = Get.put(TicketsController());
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'TIKET SAYA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Muat Ulang Tiket',
            onPressed: () => _controller.loadTickets(forceRefresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Obx(() => Tab(
                  text: 'Tiket Aktif (${_controller.activeTickets.length})',
                )),
            Obx(() => Tab(
                  text: 'Riwayat (${_controller.historyTickets.length})',
                )),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return Column(
          children: [
            // Banner Mode Offline (PB-024)
            if (_controller.isOfflineMode.value) _buildOfflineBanner(),

            // Kolom Pencarian Cepat
            _buildSearchBar(),

            // Konten Tab View (PB-025)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Tiket Aktif
                  _buildTicketsList(
                    tickets: _controller.displayedActiveTickets,
                    isActiveTab: true,
                    emptyIcon: Icons.confirmation_number_outlined,
                    emptyTitle: 'Belum Ada Tiket Aktif',
                    emptySubtitle:
                        'Tiket bioskop yang kamu pesan akan muncul di sini lengkap dengan QR Code yang bisa dibuka tanpa internet (offline).',
                    actionLabel: 'Pesan Tiket Bioskop',
                    onAction: () => Get.toNamed(Routes.bookByCinema),
                  ),

                  // Tab 2: Riwayat Tiket
                  _buildTicketsList(
                    tickets: _controller.displayedHistoryTickets,
                    isActiveTab: false,
                    emptyIcon: Icons.history_rounded,
                    emptyTitle: 'Belum Ada Riwayat',
                    emptySubtitle:
                        'Daftar tiket film yang sudah selesai ditonton atau kedaluwarsa akan tersimpan rapi di sini.',
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Banner Offline Ready (PB-024)
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF231F14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt_rounded,
              color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Offline (PB-024) • Hive Cache',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'E-ticket dimuat dari cache lokal Hive. QR Code tetap bisa dipindai saat di dalam bioskop tanpa internet.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.gold, size: 18),
            tooltip: 'Segarkan Cache',
            onPressed: () => _controller.loadTickets(forceRefresh: true),
          ),
        ],
      ),
    );
  }

  /// Search Bar Pencarian Tiket
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _controller.updateSearch,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari tiket (judul film, bioskop, atau kode booking)...',
          hintStyle:
              const TextStyle(color: AppColors.textDisabled, fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textDisabled, size: 20),
          suffixIcon: _controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.white70, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _controller.updateSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  /// List tiket atau Tampilan Kosong (Empty State)
  Widget _buildTicketsList({
    required List<TicketModel> tickets,
    required bool isActiveTab,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (tickets.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () => _controller.loadTickets(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _buildEmptyState(
                  icon: emptyIcon,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => _controller.loadTickets(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return isActiveTab
              ? _buildActiveTicketCard(ticket)
              : _buildHistoryTicketCard(ticket);
        },
      ),
    );
  }

  /// Kartu Tiket Aktif (PB-025)
  Widget _buildActiveTicketCard(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(Routes.ticketDetail, arguments: ticket),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Mini
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 62,
                      height: 88,
                      color: AppColors.card,
                      child: ticket.posterUrl.isNotEmpty
                          ? Image.network(
                              ticket.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_creation_rounded,
                                color: AppColors.textDisabled,
                              ),
                            )
                          : const Icon(Icons.movie_creation_rounded,
                              color: AppColors.textDisabled),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info Film
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                ticket.experience,
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              ticket.bookingCode,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.movieTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.cinemaName} • ${ticket.hallName}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.gold, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ticket.remainingTimeLabel,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // Baris Kursi & Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.event_seat_rounded,
                            color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Kursi: ${ticket.seatsLabel} (${ticket.seatCount} Tiket)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Check-in Simulasi (PB-025)
                      InkWell(
                        onTap: () => _controller.markTicketAsUsed(ticket),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sensors_rounded,
                                  color: Colors.white70, size: 13),
                              SizedBox(width: 4),
                              Text('Check-in',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded,
                              color: AppColors.primaryLight, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            'QR',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primaryLight, size: 15),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu Riwayat Tiket (PB-025)
  Widget _buildHistoryTicketCard(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(Routes.ticketDetail, arguments: ticket),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Mini (sedikit redup untuk riwayat)
                  Opacity(
                    opacity: 0.8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 62,
                        height: 88,
                        color: AppColors.card,
                        child: ticket.posterUrl.isNotEmpty
                            ? Image.network(
                                ticket.posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.movie_creation_rounded,
                                  color: AppColors.textDisabled,
                                ),
                              )
                            : const Icon(Icons.movie_creation_rounded,
                                color: AppColors.textDisabled),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info Riwayat Film
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      color: AppColors.success, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    ticket.historyStatusLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              ticket.bookingCode,
                              style: const TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.movieTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.cinemaName} • ${ticket.hallName}',
                          style: const TextStyle(
                              color: AppColors.textDisabled, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.showDate} • ${ticket.showTime} WIB',
                          style: const TextStyle(
                              color: AppColors.textDisabled, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // Baris Kursi & Tombol Riwayat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kursi: ${ticket.seatsLabel} • ${ticket.formattedPrice}',
                    style: const TextStyle(
                        color: AppColors.textDisabled, fontSize: 11),
                  ),
                  Row(
                    children: [
                      // Tombol Pesan Lagi
                      InkWell(
                        onTap: () => Get.toNamed(Routes.bookByCinema),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  color: AppColors.primaryLight, size: 14),
                              SizedBox(width: 4),
                              Text('Pesan Lagi',
                                  style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        children: [
                          Text(
                            'Bukti Tiket',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white70, size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.primary, size: 54),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.local_activity_rounded, size: 18),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
