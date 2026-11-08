// lib/models/seat_model.dart
// Model untuk kursi bioskop dan status keterisian (PB-020)

enum SeatStatus {
  available, // Tersedia untuk dipilih
  selected, // Sedang dipilih pengguna
  reserved, // Sudah dipesan pengguna lain
}

enum SeatType {
  regular,
  sweetbox,
}

class SeatModel {
  final String id; // Misal: "A1", "C4"
  final String row; // "A", "B", ...
  final int column; // 1, 2, ...
  SeatStatus status;
  final SeatType type;
  final int price;

  SeatModel({
    required this.id,
    required this.row,
    required this.column,
    this.status = SeatStatus.available,
    this.type = SeatType.regular,
    this.price = 50000,
  });

  bool get isAvailable => status == SeatStatus.available;
  bool get isSelected => status == SeatStatus.selected;
  bool get isReserved => status == SeatStatus.reserved;

  SeatModel copyWith({
    String? id,
    String? row,
    int? column,
    SeatStatus? status,
    SeatType? type,
    int? price,
  }) {
    return SeatModel(
      id: id ?? this.id,
      row: row ?? this.row,
      column: column ?? this.column,
      status: status ?? this.status,
      type: type ?? this.type,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'status': status.name,
      'type': type.name,
      'price': price,
    };
  }

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] as String? ?? 'A1',
      row: json['row'] as String? ?? 'A',
      column: json['column'] as int? ?? 1,
      status: SeatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SeatStatus.available,
      ),
      type: SeatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SeatType.regular,
      ),
      price: json['price'] as int? ?? 50000,
    );
  }
}
