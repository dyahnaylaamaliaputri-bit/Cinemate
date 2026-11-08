// lib/controllers/tickets_controller.dart
// Controller untuk Tab Tiket Saya: Tiket Aktif, Riwayat, & Akses Offline (PB-023 s.d. PB-025)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ticket_model.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';

class TicketsController extends GetxController {
  final TicketService _ticketService = TicketService();
  final StorageService _storage = StorageService();

  final activeTickets = <TicketModel>[].obs;
  final historyTickets = <TicketModel>[].obs;
  final isLoading = false.obs;
  final isOfflineMode = false.obs;
  final lastCachedAt = Rxn<DateTime>();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  /// Memuat seluruh tiket pengguna dari Hive cache / Supabase (PB-024, PB-025)
  Future<void> loadTickets({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final userId = await _storage.getUserId() ?? '';
      final result = await _ticketService.getUserTicketsWithMeta(
        userId: userId,
        forceRefresh: forceRefresh,
      );

      isOfflineMode.value = result.isOffline;
      lastCachedAt.value = result.cachedAt;

      final active = <TicketModel>[];
      final history = <TicketModel>[];

      for (final t in result.tickets) {
        if (t.isTicketActive) {
          active.add(t);
        } else {
          history.add(t);
        }
      }

      activeTickets.value = active;
      historyTickets.value = history;
    } catch (_) {
      isOfflineMode.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Tiket Aktif terfilter pencarian
  List<TicketModel> get displayedActiveTickets {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return activeTickets;
    return activeTickets.where((t) {
      return t.movieTitle.toLowerCase().contains(q) ||
          t.bookingCode.toLowerCase().contains(q) ||
          t.cinemaName.toLowerCase().contains(q);
    }).toList();
  }

  /// Riwayat Tiket terfilter pencarian
  List<TicketModel> get displayedHistoryTickets {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return historyTickets;
    return historyTickets.where((t) {
      return t.movieTitle.toLowerCase().contains(q) ||
          t.bookingCode.toLowerCase().contains(q) ||
          t.cinemaName.toLowerCase().contains(q);
    }).toList();
  }

  /// Update pencarian
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  /// Format waktu tersimpan cache lokal Hive
  String get formattedCacheTime {
    final dt = lastCachedAt.value;
    if (dt == null) return 'Tersimpan Offline di Hive';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'Tersimpan di Hive ($hour:$minute WIB)';
  }

  /// Simulasi Check-in / Scan QR untuk menandai tiket telah digunakan (PB-025)
  Future<void> markTicketAsUsed(TicketModel ticket) async {
    try {
      final updated = await _ticketService.updateTicketStatus(
        ticketId: ticket.id,
        newStatus: 'used',
      );

      if (updated != null) {
        // Pindahkan dari aktif ke riwayat
        activeTickets.removeWhere(
            (t) => t.id == ticket.id || t.bookingCode == ticket.bookingCode);
        historyTickets.removeWhere(
            (t) => t.id == ticket.id || t.bookingCode == ticket.bookingCode);
        historyTickets.insert(0, updated);

        Get.snackbar(
          'Check-in Berhasil 🎉',
          'Tiket ${ticket.bookingCode} (${ticket.movieTitle}) telah dipindai dan dipindahkan ke Riwayat.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.card,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon:
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint('[TicketsController] Error marking ticket as used: $e');
    }
  }
}
