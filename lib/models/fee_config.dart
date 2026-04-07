class FeeConfig {
  final TransactionFeeConfig transactionFee;
  final ReleaseFeeConfig releaseFee;
  final InactivityFeeConfig inactivityFee;
  final double bouquetRevenueShare;
  final List<FeeTier> tiers;

  FeeConfig({
    required this.transactionFee,
    required this.releaseFee,
    required this.inactivityFee,
    required this.bouquetRevenueShare,
    required this.tiers,
  });

  factory FeeConfig.fromJson(Map<String, dynamic> json) {
    return FeeConfig(
      transactionFee: TransactionFeeConfig.fromJson(json['transactionFee'] ?? {}),
      releaseFee: ReleaseFeeConfig.fromJson(json['releaseFee'] ?? {}),
      inactivityFee: InactivityFeeConfig.fromJson(json['inactivityFee'] ?? {}),
      bouquetRevenueShare: (json['bouquetRevenueShare'] ?? 0).toDouble(),
      tiers: (json['tiers'] as List? ?? []).map((t) => FeeTier.fromJson(t)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionFee': transactionFee.toJson(),
      'releaseFee': releaseFee.toJson(),
      'inactivityFee': inactivityFee.toJson(),
      'bouquetRevenueShare': bouquetRevenueShare,
      'tiers': tiers.map((t) => t.toJson()).toList(),
    };
  }
}

class TransactionFeeConfig {
  final double percentage;
  final double minimum;

  TransactionFeeConfig({required this.percentage, required this.minimum});

  factory TransactionFeeConfig.fromJson(Map<String, dynamic> json) {
    return TransactionFeeConfig(
      percentage: (json['percentage'] ?? 0).toDouble(),
      minimum: (json['minimum'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'percentage': percentage, 'minimum': minimum};
}

class ReleaseFeeConfig {
  final double percentage;
  final double minimum;

  ReleaseFeeConfig({required this.percentage, required this.minimum});

  factory ReleaseFeeConfig.fromJson(Map<String, dynamic> json) {
    return ReleaseFeeConfig(
      percentage: (json['percentage'] ?? 0).toDouble(),
      minimum: (json['minimum'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'percentage': percentage, 'minimum': minimum};
}

class InactivityFeeConfig {
  final double ratePerWeek;
  final int graceDays;

  InactivityFeeConfig({required this.ratePerWeek, required this.graceDays});

  factory InactivityFeeConfig.fromJson(Map<String, dynamic> json) {
    return InactivityFeeConfig(
      ratePerWeek: (json['ratePerWeek'] ?? 0).toDouble(),
      graceDays: json['graceDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'ratePerWeek': ratePerWeek, 'graceDays': graceDays};
}

class FeeTier {
  final double minAmount;
  final double? maxAmount;
  final double transactionPercentage;
  final double releasePercentage;

  FeeTier({
    required this.minAmount,
    this.maxAmount,
    required this.transactionPercentage,
    required this.releasePercentage,
  });

  factory FeeTier.fromJson(Map<String, dynamic> json) {
    return FeeTier(
      minAmount: (json['minAmount'] ?? 0).toDouble(),
      maxAmount: json['maxAmount'] != null ? (json['maxAmount']).toDouble() : null,
      transactionPercentage: (json['transactionPercentage'] ?? 0).toDouble(),
      releasePercentage: (json['releasePercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'transactionPercentage': transactionPercentage,
      'releasePercentage': releasePercentage,
    };
  }
}
