class GoLiveRequest {
  final String id;
  final String developerName;
  final String developerEmail;
  final String developerPhone;
  final String websiteUrl;
  final String webhookUrl;
  final String? rejectionReason;
  final String status;
  final DateTime createdAt;

  GoLiveRequest({
    required this.id,
    required this.developerName,
    required this.developerEmail,
    required this.developerPhone,
    required this.websiteUrl,
    required this.webhookUrl,
    this.rejectionReason,
    required this.status,
    required this.createdAt,
  });

  factory GoLiveRequest.fromJson(Map<String, dynamic> json) {
    return GoLiveRequest(
      id: json['_id'] ?? json['id'] ?? '',
      developerName: json['developerName'] ?? '',
      developerEmail: json['developerEmail'] ?? '',
      developerPhone: json['developerPhone'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
      webhookUrl: json['webhookUrl'] ?? '',
      rejectionReason: json['rejectionReason'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'developerName': developerName,
      'developerEmail': developerEmail,
      'developerPhone': developerPhone,
      'websiteUrl': websiteUrl,
      'webhookUrl': webhookUrl,
      'rejectionReason': rejectionReason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
