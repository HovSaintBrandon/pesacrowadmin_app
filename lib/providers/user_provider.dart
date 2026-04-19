import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/admin_service.dart';

class UserProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  AppUser? _searchedUser;
  List<AppUser> _frozenUsers = [];
  bool _isLoading = false;
  String? _error;

  AppUser? get searchedUser => _searchedUser;
  List<AppUser> get frozenUsers => _frozenUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> lookupUser(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _searchedUser = await _adminService.lookupUser(phone);
      if (_searchedUser == null) _error = 'User not found';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFrozenUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _frozenUsers = await _adminService.listFrozenAccounts();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> freezeUser(String phone, String reason) async {
    _error = null;
    try {
      final success = await _adminService.freezeAccount(phone, reason);
      if (success && _searchedUser?.phone == phone) {
        await lookupUser(phone);
      }
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfreezeUser(String phone) async {
    _error = null;
    try {
      final success = await _adminService.unfreezeAccount(phone);
      if (success && _searchedUser?.phone == phone) {
        await lookupUser(phone);
      }
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
