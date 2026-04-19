import 'package:flutter/material.dart';
import '../models/admin.dart';
import '../models/audit_log.dart';
import '../services/admin_service.dart';

class AdminManagementProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<Admin> _admins = [];
  List<String> _availablePermissions = [];
  List<AuditLog> _auditLogs = [];
  bool _isLoading = false;
  String? _error;

  List<Admin> get admins => _admins;
  List<String> get availablePermissions => _availablePermissions;
  List<AuditLog> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPermissions() => fetchAdmins();

  Future<void> fetchAdmins() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _admins = await _adminService.listAdmins();
      // Fetch authoritative list of permissions from server
      final serverPerms = await _adminService.getAllPermissions();
      if (serverPerms.isNotEmpty) {
        _availablePermissions = serverPerms..sort();
      } else {
        // Fallback to internal list if server returns empty
        await _reconstructPermissionsFromAdmins();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reconstructPermissionsFromAdmins() async {
    final Set<String> allPerms = {};
    for (var admin in _admins) {
      allPerms.addAll(admin.permissions);
    }
    // Minimal fallback
    allPerms.addAll(['view_dashboard', 'manage_transactions', 'audit_logs']);
    _availablePermissions = allPerms.toList()..sort();
    notifyListeners();
  }

  Future<bool> createAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'admin',
  }) async {
    _error = null;
    try {
      final success = await _adminService.createAdmin({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      });
      if (success) await fetchAdmins();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdminPermissions(String adminId, List<String> permissions) async {
    _error = null;
    try {
      final success = await _adminService.updateAdminPermissions(adminId, permissions);
      if (success) await fetchAdmins();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _error = null;
    try {
      return await _adminService.updatePassword(currentPassword, newPassword);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAdmin(String id) async {
    _error = null;
    try {
      final success = await _adminService.deleteAdmin(id);
      if (success) await fetchAdmins();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAuditLogs({int page = 1, int limit = 50, String? action}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _auditLogs = await _adminService.getAuditLogs(page: page, limit: limit, action: action);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteAuditLog(String id) async {
    _error = null;
    try {
      final success = await _adminService.deleteAuditLog(id);
      if (success) _auditLogs.removeWhere((l) => l.id == id);
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> exportAuditLogs({String? fromDate, String? toDate}) async {
    _error = null;
    try {
      return await _adminService.exportAuditLogs(fromDate: fromDate, toDate: toDate);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
