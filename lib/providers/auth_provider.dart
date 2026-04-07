import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AuthProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> loadPersistedAuth() async {
    _isLoading = true;
    notifyListeners();
    
    // AdminService uses ApiService singleton; wait for initialization
    _isInitialized = true;
    _isAuthenticated = _adminService.hasToken;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _adminService.login(email, password);
      if (res['success']) {
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _adminService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}
