import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  // Date range — defaults to last 24 hours
  String _fromDate = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String().substring(0, 10);
  String _toDate = DateTime.now().toIso8601String().substring(0, 10);

  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fromDate => _fromDate;
  String get toDate => _toDate;

  // Convenience getters mapping to the /admin/reports endpoint
  Map<String, dynamic> get _data => _stats?['data'] ?? _stats ?? {};

  // Volume
  double get totalVolume => (_data['totalVolume'] ?? 0).toDouble();
  double get paidVolume => (_data['paidVolume'] ?? 0).toDouble();
  double get pendingVolume => (_data['pendingVolume'] ?? 0).toDouble();

  // Earned
  double get totalEarned => (_data['totalEarned'] ?? 0).toDouble();
  double get currentlyEarned => (_data['currentlyEarned'] ?? 0).toDouble();
  double get expectedEarnings => (_data['expectedEarnings'] ?? 0).toDouble();

  // Fees
  double get transactionFees => (_data['transactionFees'] ?? 0).toDouble();
  double get paidTransactionFees => (_data['paidTransactionFees'] ?? 0).toDouble();
  double get pendingTransactionFees => (_data['pendingTransactionFees'] ?? 0).toDouble();
  double get releaseFees => (_data['releaseFees'] ?? 0).toDouble();
  double get paidReleaseFees => (_data['paidReleaseFees'] ?? 0).toDouble();
  double get pendingReleaseFees => (_data['pendingReleaseFees'] ?? 0).toDouble();
  double get holdingFees => (_data['holdingFees'] ?? 0).toDouble();
  double get paidHoldingFees => (_data['paidHoldingFees'] ?? 0).toDouble();
  double get expectedHoldingFees => (_data['expectedHoldingFees'] ?? 0).toDouble();

  // Deal counts
  int get totalDeals => (_data['totalCount'] ?? 0).toInt();
  int get activeDeals => (_data['activeCount'] ?? 0).toInt();
  int get pendingDeals => (_data['pendingCount'] ?? 0).toInt();
  int get completedDeals => (_data['completedCount'] ?? 0).toInt();
  int get disputedDeals => (_data['disputeCount'] ?? 0).toInt();
  int get refundedDeals => (_data['refundedCount'] ?? 0).toInt();
  int get cancelledDeals => (_data['cancelledCount'] ?? 0).toInt();

  Map<String, dynamic> get statusDistribution {
    // If the endpoint doesn't provide a map, we can reconstruct it from individual counts
    if (_data.containsKey('statusDistribution')) {
      return Map<String, dynamic>.from(_data['statusDistribution']);
    }
    return {
      'pending_payment': pendingDeals,
      'active': activeDeals,
      'completed': completedDeals,
      'disputed': disputedDeals,
      'refunded': refundedDeals,
    };
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
