import 'package:flutter/material.dart';
import '../models/fee_config.dart';
import '../services/admin_service.dart';

class FeeProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  FeeConfig? _config;
  bool _isLoading = false;

  FeeConfig? get config => _config;
  bool get isLoading => _isLoading;

  FeeProvider() {
    _loadInitialConfig();
    fetchConfig(); // Fetch real data on start
  }

  void _loadInitialConfig() {
    // Basic defaults while loading
    _config = FeeConfig(
      transactionFee: TransactionFeeConfig(percentage: 2.0, minimum: 20),
      releaseFee: ReleaseFeeConfig(percentage: 1.5, minimum: 10),
      holdingFee: HoldingFeeConfig(percentage: 0.5, flatAdmin: 50),
      inactivityFee: InactivityFeeConfig(ratePerWeek: 0.1, graceDays: 7),
      disputeFee: DisputeFeeConfig(flat: 500, percentage: 0, cap: 2000),
      bouquetRevenueShare: 0.5,
      tiers: [],
    );
  }

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();
    final newConfig = await _adminService.getFeeConfig();
    if (newConfig != null) {
      _config = newConfig;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateConfig(FeeConfig newConfig) async {
    _isLoading = true;
    notifyListeners();
    final success = await _adminService.updateFeeConfig(newConfig);
    if (success) {
      _config = newConfig;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> patchConfig(Map<String, dynamic> delta) async {
    _isLoading = true;
    notifyListeners();
    final success = await _adminService.patchFeeConfig(delta);
    if (success) {
      await fetchConfig(); // Refresh full config after partial update
    }
    _isLoading = false;
    return success;
  }
}
