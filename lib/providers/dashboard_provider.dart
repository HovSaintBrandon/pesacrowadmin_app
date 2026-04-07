import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  // Date range — defaults to current year
  String _fromDate = '${DateTime.now().year}-01-01';
  String _toDate = '${DateTime.now().year}-12-31';

  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fromDate => _fromDate;
  String get toDate => _toDate;

  // Convenience getters
  double get totalVolume =>
      (_stats?['data']?['totalVolume'] ?? _stats?['totalVolume'] ?? 0).toDouble();
  double get totalRevenue =>
      (_stats?['data']?['totalRevenue'] ?? _stats?['totalRevenue'] ?? 0).toDouble();
  int get activeDeals =>
      (_stats?['data']?['activeDeals'] ?? _stats?['activeDeals'] ?? 0).toInt();
  int get pendingDeals =>
      (_stats?['data']?['pendingDeals'] ?? _stats?['pendingDeals'] ?? 0).toInt();
  int get completedDeals =>
      (_stats?['data']?['completedDeals'] ?? _stats?['completedDeals'] ?? 0).toInt();
  int get disputedDeals =>
      (_stats?['data']?['disputedDeals'] ?? _stats?['disputedDeals'] ?? 0).toInt();
  Map<String, dynamic> get statusDistribution {
    final raw = _stats?['data']?['statusDistribution'] ?? _stats?['statusDistribution'] ?? {};
    return Map<String, dynamic>.from(raw);
  }

  Future<void> fetchReports({String? from, String? to}) async {
    if (from != null) _fromDate = from;
    if (to != null) _toDate = to;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.getReports(_fromDate, _toDate);
      _stats = result;
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
