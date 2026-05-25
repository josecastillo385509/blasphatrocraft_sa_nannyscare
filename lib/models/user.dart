enum UserRole { tutor, cuidador, administrador, supervisor }

class AppUser {
  final String id;
  final String email;
  final String password; // En producción debería estar hasheado
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'name': name,
        'role': role.name,
        'photoUrl': photoUrl,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        email: json['email'],
        password: json['password'],
        name: json['name'],
        role: UserRole.values.firstWhere((r) => r.name == json['role']),
        photoUrl: json['photoUrl'],
        phone: json['phone'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? phone,
  }) {
    return AppUser(
      id: id,
      email: email,
      password: password,
      name: name ?? this.name,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
