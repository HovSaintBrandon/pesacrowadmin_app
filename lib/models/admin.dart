class Admin {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<String> permissions;
  final DateTime? createdAt;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.permissions,
    this.createdAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'admin',
      permissions: List<String>.from(json['permissions'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'permissions': permissions,
      };
}
