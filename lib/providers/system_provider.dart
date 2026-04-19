import 'package:flutter/material.dart';
import '../models/system_config.dart';
import '../services/admin_service.dart';

class SystemProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  WebhookConfig? _webhookConfig;
  OtpConfig? _otpConfig;
  SystemHealth? _health;
  bool _isLoading = false;
  String? _error;

  WebhookConfig? get webhookConfig => _webhookConfig;
  OtpConfig? get otpConfig => _otpConfig;
  SystemHealth? get health => _health;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        fetchWebhookConfig(),
        fetchOtpConfig(),
        fetchHealth(),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchWebhookConfig() async {
    _webhookConfig = await _adminService.getWebhookConfig();
    notifyListeners();
  }

  Future<void> fetchOtpConfig() async {
    _otpConfig = await _adminService.getOtpConfig();
    notifyListeners();
  }

  Future<void> fetchHealth() async {
    _health = await _adminService.getSystemHealth();
    notifyListeners();
  }

  Future<bool> updateWebhooks(Map<String, dynamic> delta) async {
    _error = null;
    try {
      final success = await _adminService.updateWebhookConfig(delta);
      if (success) await fetchWebhookConfig();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOtp(Map<String, dynamic> delta) async {
    _error = null;
    try {
      final success = await _adminService.updateOtpConfig(delta);
      if (success) await fetchOtpConfig();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendAnnouncement({required String target, required String message, required String via}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _adminService.sendAnnouncement(target: target, message: message, via: via);
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
}
