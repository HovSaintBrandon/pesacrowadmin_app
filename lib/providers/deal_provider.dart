import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../services/admin_service.dart';

class DealProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<Deal> _deals = [];
  bool _isLoading = false;
  String? _error;
  Deal? _selectedDeal;

  int _currentPage = 1;
  int _totalCount = 0;
  static const int _pageSize = 20;

  List<Deal> get deals => _deals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Deal? get selectedDeal => _selectedDeal;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil().clamp(1, 999);

  Future<void> fetchDeals({
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.listTransactions(
        page: page,
        limit: _pageSize,
        status: status,
        search: search,
        fromDate: fromDate,
        toDate: toDate,
      );
      _deals = result['deals'] as List<Deal>;
      _totalCount = result['total'] as int;
      _currentPage = page;
    } catch (e) {
      _error = 'Failed to load transactions: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Deal?> fetchDealDetail(String transactionId) async {
    try {
      final deal = await _adminService.getTransactionDetail(transactionId);
      if (deal != null) {
        _selectedDeal = deal;
        notifyListeners();
      }
      return deal;
    } catch (_) {
      return null;
    }
  }

  void selectDeal(Deal? deal) {
    _selectedDeal = deal;
    notifyListeners();
  }

  Future<bool> retryPayout(String transactionId) async {
    return await _adminService.retryPayout(transactionId);
  }

  Future<bool> resolveDispute(String transactionId, String decision, String resolution) async {
    return await _adminService.resolveDispute(transactionId, decision, resolution);
  }

  Future<bool> triggerReversal(String transactionId, String remarks) async {
    return await _adminService.triggerReversal(transactionId, remarks);
  }

  Future<bool> cancelDeal(String transactionId) async {
    return await _adminService.cancelDeal(transactionId);
  }
}
