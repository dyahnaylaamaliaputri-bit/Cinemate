// lib/models/fnb_order_model.dart
// Model untuk transaksi & E-Voucher pesanan Makanan & Minuman (PB-028, PB-029, PB-030)

class FnbOrderItemModel {
  final String fnbItemId;
  final String name;
  final int price;
  final int quantity;
  final int subtotal;
  final String? note;

  const FnbOrderItemModel({
    required this.fnbItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.note,
  });

  factory FnbOrderItemModel.fromJson(Map<String, dynamic> json) {
    return FnbOrderItemModel(
      fnbItemId: json['fnb_item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fnb_item_id': fnbItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      if (note != null) 'note': note,
    };
  }

  String get formattedPrice =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  String get formattedSubtotal =>
      'Rp ${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class FnbOrderModel {
  final String id;
  final String userId;
  final String cinemaId;
  final String cinemaName;
  final String pickupCode; // e.g. "FNB-93821"
  final String status; // 'processing', 'ready', 'completed'
  final String
      pickupMethod; // 'counter' (Pick-up di Concession) atau 'delivery' (Antar ke Kursi)
  final String? studioNumber;
  final String? seatNumber;
  final int subtotal;
  final int serviceFee;
  final int totalPrice;
  final String paymentMethod;
  final DateTime createdAt;
  final List<FnbOrderItemModel> items;

  const FnbOrderModel({
    required this.id,
    required this.userId,
    required this.cinemaId,
    required this.cinemaName,
    required this.pickupCode,
    required this.status,
    this.pickupMethod = 'counter',
    this.studioNumber,
    this.seatNumber,
    required this.subtotal,
    this.serviceFee = 2000,
    required this.totalPrice,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  factory FnbOrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<FnbOrderItemModel> parsedItems = rawItems
        .map((item) =>
            FnbOrderItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return FnbOrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      cinemaId: json['cinema_id']?.toString() ?? '',
      cinemaName: json['cinema_name']?.toString() ?? 'Cinemate Concession',
      pickupCode: json['pickup_code']?.toString() ?? 'FNB-00000',
      status: json['status']?.toString() ?? 'processing',
      pickupMethod: json['pickup_method']?.toString() ?? 'counter',
      studioNumber: json['studio_number']?.toString(),
      seatNumber: json['seat_number']?.toString(),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      serviceFee: (json['service_fee'] as num?)?.toInt() ?? 2000,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'QRIS',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cinema_id': cinemaId,
      'cinema_name': cinemaName,
      'pickup_code': pickupCode,
      'status': status,
      'pickup_method': pickupMethod,
      if (studioNumber != null) 'studio_number': studioNumber,
      if (seatNumber != null) 'seat_number': seatNumber,
      'subtotal': subtotal,
      'service_fee': serviceFee,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  FnbOrderModel copyWith({
    String? id,
    String? userId,
    String? cinemaId,
    String? cinemaName,
    String? pickupCode,
    String? status,
    String? pickupMethod,
    String? studioNumber,
    String? seatNumber,
    int? subtotal,
    int? serviceFee,
    int? totalPrice,
    String? paymentMethod,
    DateTime? createdAt,
    List<FnbOrderItemModel>? items,
  }) {
    return FnbOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cinemaId: cinemaId ?? this.cinemaId,
      cinemaName: cinemaName ?? this.cinemaName,
      pickupCode: pickupCode ?? this.pickupCode,
      status: status ?? this.status,
      pickupMethod: pickupMethod ?? this.pickupMethod,
      studioNumber: studioNumber ?? this.studioNumber,
      seatNumber: seatNumber ?? this.seatNumber,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  String get formattedTotalPrice =>
      'Rp ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Sedang Disiapkan ⏳';
      case 'ready':
        return 'Siap Diambil ✨';
      case 'completed':
        return 'Selesai Diambil ✅';
      default:
        return status;
    }
  }

  String get pickupMethodLabel {
    if (pickupMethod == 'delivery') {
      return 'Antar ke Studio ${studioNumber ?? ''} (Kursi ${seatNumber ?? ''})';
    }
    return 'Ambil di Counter Concession Bioskop';
  }

  /// String muatan QR code unik untuk discan petugas bioskop (PB-029)
  String get qrPayload => 'CINEMATE_FNB:$pickupCode:$id:$cinemaId:$status';
}
