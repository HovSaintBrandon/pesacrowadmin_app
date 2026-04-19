import 'package:flutter/material.dart';
import '../models/financial_stats.dart';
import '../services/admin_service.dart';

class FinancialsProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  FinancialStats? _stats;
  bool _isLoading = false;
  String? _error;

  FinancialStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _adminService.getFinancialStats();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
