import 'dart:async';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/admin.dart';

class AuthProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Admin? _currentUser;
  Timer? _refreshTimer;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  Admin? get currentUser => _currentUser;

  /// Helper to check if current user has a specific permission
  bool hasPermission(String perm) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'super_admin') return true;
    if (_currentUser!.permissions.contains('*')) return true;
    return _currentUser!.permissions.contains(perm);
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // Poll every 60 seconds to keep permissions in sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => refreshProfile());
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refreshProfile() async {
    if (!_isAuthenticated) return;
    try {
      final updatedUser = await _adminService.getProfile();
      if (updatedUser != null) {
        if (_currentUser != null && 
            _currentUser!.permissions.join(',') != updatedUser.permissions.join(',')) {
          print('AuthProvider: Permissions changed, updating UI');
        }
        _currentUser = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        await logout();
      }
    }
  }

  Future<void> loadPersistedAuth() async {
    _isLoading = true;
    notifyListeners();
    
    _isInitialized = true;
    _isAuthenticated = _adminService.hasToken;
    if (_isAuthenticated) {
      await refreshProfile();
      _startRefreshTimer();
    }
    
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
        
        final adminData = res['data']?['admin'] ?? res['data']?['user'];
        if (adminData != null && adminData is Map<String, dynamic>) {
          _currentUser = Admin.fromJson(adminData);
        } else {
          _currentUser = await _adminService.getProfile();
        }
        
        _startRefreshTimer();
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
    _stopRefreshTimer();
    await _adminService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}
