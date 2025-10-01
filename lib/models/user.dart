class User {
  final int id;
  final String name;
  final String email;
  final int roomNumber;
  final DateTime createdAt;
  // FIX: These fields are now nullable to match the backend's UserOut schema
  final String? role;
  final bool? isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.createdAt,
    // FIX: These are now optional
    this.role,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roomNumber: json['room_number'],
      createdAt: DateTime.parse(json['created_at']),
      // FIX: Safely parse these fields only if they exist in the JSON response
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}

