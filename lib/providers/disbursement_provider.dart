import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class DisbursementProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _pendingDisbursementId;
  String? _error;

  bool get isLoading => _isLoading;
  String? get pendingDisbursementId => _pendingDisbursementId;
  String? get error => _error;
  bool get awaitingOtp => _pendingDisbursementId != null;

  Future<bool> initiate({
    required String channel,
    required double amount,
    required String phone,
    required String remarks,
    String? accountReference,
  }) async {
    _isLoading = true;
    _error = null;
    _pendingDisbursementId = null;
    notifyListeners();

    try {
      final id = await _adminService.initiateManualDisbursement(
        channel: channel,
        amount: amount,
        phone: phone,
        remarks: remarks,
        accountReference: accountReference,
      );
      if (id != null) {
        _pendingDisbursementId = id;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> confirm(String otp) async {
    if (_pendingDisbursementId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _adminService.confirmManualDisbursement(_pendingDisbursementId!, otp);
      if (success) _pendingDisbursementId = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void cancelPending() {
    _pendingDisbursementId = null;
    _error = null;
    notifyListeners();
  }
}
