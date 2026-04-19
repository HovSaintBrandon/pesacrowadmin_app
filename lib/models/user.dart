class AppUser {
  final String phone;
  final String name;
  final int dealCount;
  final bool isFrozen;
  final String? freezeReason;
  final DateTime createdAt;

  AppUser({
    required this.phone,
    required this.name,
    required this.dealCount,
    required this.isFrozen,
    this.freezeReason,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      dealCount: (json['dealCount'] ?? 0).toInt(),
      isFrozen: json['isFrozen'] ?? false,
      freezeReason: json['freezeReason'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'name': name,
      'dealCount': dealCount,
      'isFrozen': isFrozen,
      'freezeReason': freezeReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
