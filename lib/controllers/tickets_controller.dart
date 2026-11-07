// lib/controllers/tickets_controller.dart
// Controller untuk Tab Tiket Saya: Tiket Aktif & Riwayat (PB-023, PB-024, PB-025)

import 'package:get/get.dart';
import '../models/ticket_model.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';

class TicketsController extends GetxController {
  final TicketService _ticketService = TicketService();
  final StorageService _storage = StorageService();

  final activeTickets = <TicketModel>[].obs;
  final historyTickets = <TicketModel>[].obs;
  final isLoading = false.obs;
  final isOfflineMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  /// Memuat seluruh tiket pengguna dari Hive cache / Supabase
  Future<void> loadTickets({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final userId = await _storage.getUserId() ?? '';
      final tickets = await _ticketService.getUserTickets(userId: userId, forceRefresh: forceRefresh);

      final active = <TicketModel>[];
      final history = <TicketModel>[];

      for (final t in tickets) {
        if (t.isActive) {
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
}
