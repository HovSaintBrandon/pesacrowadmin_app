class BlacklistItem {
  final String phone;
  final String reason;
  final String bannedAt;
  final String bannedBy;

  BlacklistItem({
    required this.phone,
    required this.reason,
    required this.bannedAt,
    required this.bannedBy,
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) {
    return BlacklistItem(
      phone: json['phone'] ?? '',
      reason: json['reason'] ?? '',
      bannedAt: json['bannedAt'] ?? '',
      bannedBy: json['bannedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'reason': reason,
      'bannedAt': bannedAt,
      'bannedBy': bannedBy,
    };
  }
}
