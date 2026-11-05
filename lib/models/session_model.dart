// lib/models/session_model.dart
// Model sesi login
// Referensi: PB-007, R-06

class SessionModel {
  final String id;
  final String userId;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime createdAt;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.expiresAt,
    required this.createdAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tokenHash: map['token_hash'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Cek apakah sesi masih valid
  bool get isValid => expiresAt.isAfter(DateTime.now().toUtc());

  @override
  String toString() =>
      'SessionModel(id: $id, userId: $userId, expiresAt: $expiresAt)';
}
