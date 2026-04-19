import 'package:flutter/material.dart';
import '../models/mpesa_balance.dart';
import '../models/mpesa_balance_snapshot.dart';
import '../services/admin_service.dart';

class MpesaProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<MpesaBalance> _balances = [];
  List<MpesaBalanceSnapshot> _history = [];
  bool _isLoading = false;
  String? _lastResult;

  List<MpesaBalance> get balances => _balances;
  List<MpesaBalanceSnapshot> get history => _history;
  bool get isLoading => _isLoading;
  String? get lastResult => _lastResult;

  Future<bool> registerC2B() => _run(() => _adminService.registerC2B());

  Future<bool> simulateC2B(double amount, String msisdn, String billRef) =>
      _run(() => _adminService.simulateC2B(amount, msisdn, billRef));

  Future<bool> triggerReversal(String transactionId, String remarks) =>
      _run(() => _adminService.triggerReversal(transactionId, remarks));

  Future<bool> b2bPaybill({
    required double amount,
    required String destinationShortcode,
    required String accountReference,
    required String remarks,
  }) =>
      _run(() => _adminService.b2bPaybill(
            amount: amount,
            destinationShortcode: destinationShortcode,
            accountReference: accountReference,
            remarks: remarks,
          ));

  Future<bool> queryBalance(String remarks) async {
    final success = await _run(() => _adminService.queryBalance(remarks));
    if (success) {
      await fetchLatestBalance();
      await fetchBalanceHistory();
    }
    return success;
  }

  Future<void> fetchLatestBalance() async {
    _isLoading = true;
    notifyListeners();
    try {
      _balances = await _adminService.getLatestBalance();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBalanceHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _adminService.getBalanceHistory();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> queryTransactionStatus(String identifier, {bool isConversationId = false}) =>
      _run(() => _adminService.queryTransactionStatus(identifier,
          isConversationId: isConversationId));

  Future<bool> registerPullTransactions({
    required String nominatedNumber,
    required String callbackUrl,
  }) =>
      _run(() => _adminService.registerPullTransactions(
            nominatedNumber: nominatedNumber,
            callbackUrl: callbackUrl,
          ));

  Future<bool> queryPullTransactions({
    required String startDate,
    required String endDate,
    int offsetValue = 0,
  }) =>
      _run(() => _adminService.queryPullTransactions(
            startDate: startDate,
            endDate: endDate,
            offsetValue: offsetValue,
          ));

  String? _error;
  String? get error => _error;

  Future<bool> _run(Future<bool> Function() fn) async {
    _isLoading = true;
    _lastResult = null;
    _error = null;
    notifyListeners();
    try {
      final success = await fn();
      _lastResult = success ? 'success' : 'failed';
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _lastResult = 'error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
