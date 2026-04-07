import 'package:flutter/material.dart';
import '../models/blacklist_item.dart';
import '../services/admin_service.dart';

class BlacklistProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  List<BlacklistItem> _blacklist = [];
  bool _isLoading = false;
  String? _error;

  List<BlacklistItem> get blacklist => _blacklist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBlacklist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _adminService.getBlacklist();
      _blacklist = list;
    } catch (e) {
      _error = 'Failed to load blacklist: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> banPhone(String phone, String reason) async {
    try {
      final success = await _adminService.banPhone(phone, reason);
      if (success) await fetchBlacklist();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unbanPhone(String phone) async {
    try {
      final success = await _adminService.unbanPhone(phone);
      if (success) await fetchBlacklist();
      return success;
    } catch (_) {
      return false;
    }
  }
}
