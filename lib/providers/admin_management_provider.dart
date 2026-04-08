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

  Future<void> fetchAdmins() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _admins = await _adminService.listAdmins();
    } catch (e) {
      _error = 'Failed to load admins: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPermissions() async {
    try {
      _availablePermissions = await _adminService.getAllPermissions();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'admin',
    List<String> permissions = const [],
  }) async {
    try {
      final success = await _adminService.createAdmin({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'permissions': permissions,
      });
      if (success) await fetchAdmins();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePermissions(String adminId, List<String> permissions) async {
    try {
      final success = await _adminService.updateAdminPermissions(adminId, permissions);
      if (success) await fetchAdmins();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      return await _adminService.updatePassword(currentPassword, newPassword);
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAdmin(String id) async {
    try {
      final success = await _adminService.deleteAdmin(id);
      if (success) await fetchAdmins();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchAuditLogs({int page = 1, String? action}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _auditLogs = await _adminService.getAuditLogs(page: page, action: action);
    } catch (e) {
      _error = 'Failed to load audit logs: $e';
    }
    _isLoading = false;
    notifyListeners();
  }
}
