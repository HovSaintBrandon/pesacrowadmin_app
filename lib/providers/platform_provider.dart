import 'package:flutter/material.dart';
import '../models/go_live_request.dart';
import '../models/platform.dart';
import '../services/admin_service.dart';

class PlatformProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<GoLiveRequest> _goLiveRequests = [];
  List<Platform> _platforms = [];
  bool _isLoading = false;
  String? _error;

  List<GoLiveRequest> get goLiveRequests => _goLiveRequests;
  List<Platform> get platforms => _platforms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGoLiveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goLiveRequests = await _adminService.getGoLiveRequests();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveGoLiveRequest(String id) async {
    _error = null;
    try {
      final ok = await _adminService.approveGoLiveRequest(id);
      if (ok) await fetchGoLiveRequests();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectGoLiveRequest(String id, String reason) async {
    _error = null;
    try {
      final ok = await _adminService.rejectGoLiveRequest(id, reason);
      if (ok) await fetchGoLiveRequests();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchPlatforms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _platforms = await _adminService.getPlatforms();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> togglePlatformFreeze(String id) async {
    _error = null;
    try {
      final ok = await _adminService.togglePlatformFreeze(id);
      if (ok) await fetchPlatforms();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rotatePlatformKey(String id) async {
    _error = null;
    try {
      final ok = await _adminService.rotatePlatformKey(id);
      if (ok) await fetchPlatforms();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlatform(String id, Map<String, dynamic> data) async {
    _error = null;
    try {
      final ok = await _adminService.updatePlatform(id, data);
      if (ok) await fetchPlatforms();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlatform(String id) async {
    _error = null;
    try {
      final ok = await _adminService.deletePlatform(id);
      if (ok) await fetchPlatforms();
      return ok;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
