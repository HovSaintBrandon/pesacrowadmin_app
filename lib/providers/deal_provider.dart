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
      _error = e.toString().replaceFirst('Exception: ', '');
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
    _error = null;
    try {
      return await _adminService.retryPayout(transactionId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveDispute(String transactionId, String decision, String resolution) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _adminService.resolveDispute(transactionId, decision, resolution);
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDisputeDetail(String transactionId) async {
    try {
      return await _adminService.getDisputeDetail(transactionId);
    } catch (_) {
      return {'success': false, 'message': 'Failed to load dispute detail'};
    }
  }

  Future<bool> addDisputeNote(String transactionId, String note) async {
    _error = null;
    try {
      final ok = await _adminService.addDisputeNote(transactionId, note);
      if (ok) await fetchDisputeDetail(transactionId);
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> exportTransactions({String? fromDate, String? toDate, String? status}) async {
    _error = null;
    try {
      return await _adminService.exportTransactions(fromDate: fromDate, toDate: toDate, status: status);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> triggerReversal(String transactionId, String remarks) async {
    _error = null;
    try {
      return await _adminService.triggerReversal(transactionId, remarks);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelDeal(String transactionId) async {
    _error = null;
    try {
      return await _adminService.cancelDeal(transactionId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> initiateRefund(String transactionId, String reason) async {
    _error = null;
    try {
      return await _adminService.initiateRefund(transactionId, reason);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
