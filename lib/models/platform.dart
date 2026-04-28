class Platform {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String webhookUrl;
  final String settlementPhone;
  final bool isActive;
  final String? apiKey;
  final DateTime createdAt;

  Platform({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.webhookUrl,
    required this.settlementPhone,
    required this.isActive,
    this.apiKey,
    required this.createdAt,
  });

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      webhookUrl: json['webhookUrl'] ?? '',
      settlementPhone: json['settlementPhone'] ?? '',
      isActive: json['isActive'] ?? true,
      apiKey: json['apiKey'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'webhookUrl': webhookUrl,
      'settlementPhone': settlementPhone,
      'isActive': isActive,
      'apiKey': apiKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
