import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isSending = false;
  String? _error;

  bool get isSending => _isSending;
  String? get error => _error;

  Future<bool> sendAnnouncement({
    required String target,
    required String message,
    required String via,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _adminService.sendAnnouncement(
        target: target,
        message: message,
        via: via,
      );
      _isSending = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }
}
