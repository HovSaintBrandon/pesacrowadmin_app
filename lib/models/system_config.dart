import 'dart:convert';

class WebhookConfig {
  final Map<String, dynamic> _raw;

  WebhookConfig({Map<String, dynamic>? raw}) : _raw = raw ?? {};

  factory WebhookConfig.fromJson(dynamic json) {
    if (json is Map) {
      return WebhookConfig(raw: Map<String, dynamic>.from(json));
    }
    return WebhookConfig();
  }

  String _getValue(String key) {
    final entry = _raw[key];
    if (entry is Map) {
      return entry['value']?.toString() ?? '';
    }
    return '';
  }

  String get primaryUrl => _getValue('MPESA_CALLBACK_URL');
  String get b2cResultUrl => _getValue('MPESA_B2C_RESULT_URL');
  String get b2cTimeoutUrl => _getValue('MPESA_B2C_TIMEOUT_URL');
  
  Map<String, dynamic> toJson() => _raw;
}

class OtpConfig {
  final String effectivePhone;
  final String source;
  final String? updatedBy;
  final DateTime? updatedAt;

  OtpConfig({
    required this.effectivePhone,
    required this.source,
    this.updatedBy,
    this.updatedAt,
  });

  factory OtpConfig.fromJson(dynamic json) {
    if (json is! Map) {
      return OtpConfig(effectivePhone: '', source: 'unknown');
    }
    return OtpConfig(
      effectivePhone: json['effectivePhone']?.toString() ?? '',
      source: json['source']?.toString() ?? 'unknown',
      updatedBy: json['updatedBy']?.toString(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  String get adminPhone => effectivePhone;
  bool get isOnline => true;
  int? get batteryStatus => null;
}

class SystemHealth {
  final String status;
  final String humanUptime;
  final String dbStatus;
  final String darajaStatus;
  final bool smsConfigured;
  final Map<String, dynamic> memory;
  final Map<String, dynamic> platform;
  final DateTime checkedAt;

  SystemHealth({
    required this.status,
    required this.humanUptime,
    required this.dbStatus,
    required this.darajaStatus,
    required this.smsConfigured,
    required this.memory,
    required this.platform,
    required this.checkedAt,
  });

  factory SystemHealth.fromJson(dynamic json) {
    if (json is! Map) {
      return SystemHealth(
        status: 'unknown',
        humanUptime: 'N/A',
        dbStatus: 'unknown',
        darajaStatus: 'unknown',
        smsConfigured: false,
        memory: {},
        platform: {},
        checkedAt: DateTime.now(),
      );
    }
    return SystemHealth(
      status: json['status']?.toString() ?? 'unknown',
      humanUptime: (json['uptime'] is Map) ? (json['uptime']['human']?.toString() ?? 'N/A') : 'N/A',
      dbStatus: (json['database'] is Map) ? (json['database']['status']?.toString() ?? 'disconnected') : 'disconnected',
      darajaStatus: (json['daraja'] is Map) ? (json['daraja']['status']?.toString() ?? 'unknown') : 'unknown',
      smsConfigured: (json['sms'] is Map) ? (json['sms']['configured'] == true) : false,
      memory: Map<String, dynamic>.from(json['memory'] ?? {}),
      platform: Map<String, dynamic>.from(json['platform'] ?? {}),
      checkedAt: json['checkedAt'] != null ? (DateTime.tryParse(json['checkedAt'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }

  double get heapUsedMB => (memory['heapUsedMB'] ?? 0).toDouble();
  double get withdrawableBalance => (platform['withdrawableBalance'] ?? 0).toDouble();
}
