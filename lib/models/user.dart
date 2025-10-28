// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final int roomNumber;
  final DateTime createdAt;
  final String? role;
  final bool? isActive;
  final bool? isMessActive; // ADDED

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.createdAt,
    this.role,
    this.isActive,
    this.isMessActive, // ADDED
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roomNumber: json['room_number'],
      createdAt: DateTime.parse(json['created_at']),
      role: json['role'],
      isActive: json['is_active'],
      isMessActive: json['is_mess_active'], // ADDED
    );
  }

  // --- NEW METHOD ---
  User copyWith({
    int? id,
    String? name,
    String? email,
    int? roomNumber,
    DateTime? createdAt,
    String? role,
    bool? isActive,
    bool? isMessActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isMessActive: isMessActive ?? this.isMessActive,
    );
  }
  // --- END NEW METHOD ---
}