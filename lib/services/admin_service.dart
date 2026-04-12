import 'dart:convert';
import 'api_service.dart';
import '../models/admin.dart';
import '../models/audit_log.dart';
import '../models/deal.dart';
import '../models/blacklist_item.dart';
import '../models/fee_config.dart';
import '../models/mpesa_balance.dart';
import '../models/mpesa_balance_snapshot.dart';

class AdminService {
  final ApiService _api = ApiService();
  ApiService get api => _api;
  bool get hasToken => _api.hasToken;

  // ─── AUTH ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api.post('/admin/login', body: {'email': email, 'password': password});
    final data = Map<String, dynamic>.from(jsonDecode(res.body));
    if (res.statusCode == 200 && data['success'] == true) {
      await _api.setToken(data['data']['token']);
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await _api.post('/admin/logout');
    } catch (e) {
      print('❌ AdminService: Error during logout: $e');
    }
    await _api.clearToken();
  }

  Future<Admin?> getProfile() async {
    try {
      final res = await _api.get('/admin/profile');
      final data = jsonDecode(res.body);
      
      // Handle both { "success": true, "data": {...} } and direct {...}
      final profileData = (data is Map && data['data'] != null) ? data['data'] : data;
      if (profileData is Map<String, dynamic>) {
        return Admin.fromJson(profileData);
      }
    } catch (e) {
      print('❌ AdminService: Error fetching profile: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> impersonate(String phone) async {
    final res = await _api.post('/admin/impersonate', body: {'phone': phone});
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ─── FEE MANAGEMENT ──────────────────────────────────────────────────────
  Future<FeeConfig?> getFeeConfig() async {
    final res = await _api.get('/admin/fees');
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final innerData = data['data'];
      if (innerData != null && innerData['fees'] != null) {
        return FeeConfig.fromJson(innerData['fees']);
      }
      return FeeConfig.fromJson(innerData);
    }
    return null;
  }

  Future<bool> updateFeeConfig(FeeConfig config) async {
    final res = await _api.post('/admin/fees/update', body: config.toJson());
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> patchFeeConfig(Map<String, dynamic> delta) async {
    final res = await _api.patch('/admin/fees', body: delta);
    return jsonDecode(res.body)['success'] ?? false;
  }

  // ─── TRANSACTIONS & REPORTS ───────────────────────────────────────────────
  Future<Map<String, dynamic>> listTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
    };
    final res = await _api.get('/admin/transactions', query: query);
    final data = Map<String, dynamic>.from(jsonDecode(res.body));
    if (data['success'] == true) {
      final innerData = data['data'];
      List rawList = [];
      int total = 0;
      
      if (innerData is List) {
        rawList = innerData;
        total = data['total'] ?? rawList.length;
      } else if (innerData is Map) {
        rawList = innerData['transactions'] ?? [];
        total = innerData['total'] ?? data['total'] ?? rawList.length;
      }

      return <String, dynamic>{
        'deals': rawList.map((t) => Deal.fromJson(Map<String, dynamic>.from(t))).toList(),
        'total': total.toInt(),
        'page': (data['page'] ?? page).toInt(),
      };
    }
    return <String, dynamic>{'deals': <Deal>[], 'total': 0, 'page': page};
  }

  Future<Deal?> getTransactionDetail(String transactionId) async {
    final res = await _api.get('/admin/transactions/$transactionId');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return Deal.fromJson(data['data']);
    return null;
  }

  Future<Map<String, dynamic>> getReports(String fromDate, String toDate) async {
    final res = await _api.get('/admin/reports', query: {'fromDate': fromDate, 'toDate': toDate});
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<List<AuditLog>> getAuditLogs({int page = 1, int limit = 50, String? action}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (action != null && action.isNotEmpty) 'action': action,
    };
    final res = await _api.get('/admin/audit-logs', query: query);
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => AuditLog.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> retryPayout(String transactionId) async {
    final res = await _api.post('/admin/deals/$transactionId/retry-payout');
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> cancelDeal(String transactionId) async {
    final res = await _api.post('/deals/$transactionId/cancel');
    return jsonDecode(res.body)['success'] ?? false;
  }

  // ─── DISPUTE RESOLUTION ───────────────────────────────────────────────────
  Future<bool> resolveDispute(String transactionId, String decision, String resolution) async {
    final res = await _api.post('/admin/resolve-dispute/$transactionId', body: {
      'decision': decision,
      'resolution': resolution,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  // ─── BLACKLIST ────────────────────────────────────────────────────────────
  Future<bool> banPhone(String phone, String reason) async {
    final res = await _api.post('/admin/ban-phone', body: {'phone': phone, 'reason': reason});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> unbanPhone(String phone) async {
    final res = await _api.post('/admin/unban-phone', body: {'phone': phone});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<List<BlacklistItem>> getBlacklist() async {
    final res = await _api.get('/admin/blacklist');
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((b) => BlacklistItem.fromJson(b)).toList();
    }
    return [];
  }

  // ─── ADMIN MANAGEMENT ────────────────────────────────────────────────────
  Future<bool> createAdmin(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/create', body: body);
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<List<Admin>> listAdmins() async {
    final res = await _api.get('/admin/list');
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((a) => Admin.fromJson(a)).toList();
    }
    return [];
  }

  Future<bool> updateAdminPermissions(String adminId, List<String> permissions) async {
    final res = await _api.patch('/admin/$adminId/permissions', body: {'permissions': permissions});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    final res = await _api.post('/admin/update-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> deleteAdmin(String id) async {
    final res = await _api.delete('/admin/$id');
    return jsonDecode(res.body)['success'] ?? false;
  }

  // ─── M-PESA TOOLS ─────────────────────────────────────────────────────────
  Future<bool> registerC2B() async {
    final res = await _api.post('/admin/mpesa/c2b/register');
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> simulateC2B(double amount, String msisdn, String billRef) async {
    final res = await _api.post('/admin/mpesa/c2b/simulate', body: {
      'amount': amount,
      'msisdn': msisdn,
      'billRefNumber': billRef,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> triggerReversal(String transactionId, String remarks) async {
    final res = await _api.post('/admin/transactions/$transactionId/reversal', body: {'remarks': remarks});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> b2bPaybill({
    required double amount,
    required String destinationShortcode,
    required String accountReference,
    required String remarks,
  }) async {
    final res = await _api.post('/admin/mpesa/b2b/pay', body: {
      'amount': amount,
      'destinationShortcode': destinationShortcode,
      'accountReference': accountReference,
      'remarks': remarks,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> queryBalance(String remarks) async {
    final res = await _api.post('/admin/mpesa/balance/query', body: {'remarks': remarks});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<List<MpesaBalance>> getLatestBalance() async {
    final res = await _api.get('/admin/mpesa/balance');
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final raw = data['data'];
      if (raw is List) return raw.map((b) => MpesaBalance.fromJson(b)).toList();
      if (raw is Map) {
        final accounts = (raw['accounts'] ?? raw['balances']) as List?;
        if (accounts != null) return accounts.map((b) => MpesaBalance.fromJson(b)).toList();
        return [MpesaBalance.fromJson(Map<String, dynamic>.from(raw))];
      }
    }
    return [];
  }

  Future<List<MpesaBalanceSnapshot>> getBalanceHistory() async {
    final res = await _api.get('/admin/mpesa/balance/history');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List).map((s) => MpesaBalanceSnapshot.fromJson(Map<String, dynamic>.from(s))).toList();
    }
    return [];
  }

  Future<bool> queryTransactionStatus(String identifier, {bool isConversationId = false}) async {
    final res = await _api.post('/admin/mpesa/status/query', body: {
      'identifier': identifier,
      'isConversationId': isConversationId,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> registerPullTransactions({
    required String nominatedNumber,
    required String callbackUrl,
  }) async {
    final res = await _api.post('/admin/mpesa/pull/register', body: {
      'nominatedNumber': nominatedNumber,
      'callbackUrl': callbackUrl,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<bool> queryPullTransactions({
    required String startDate,
    required String endDate,
    int offsetValue = 0,
  }) async {
    final res = await _api.post('/admin/mpesa/pull/query', body: {
      'startDate': startDate,
      'endDate': endDate,
      'offsetValue': offsetValue,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }

  // ─── MANUAL DISBURSEMENT ──────────────────────────────────────────────────
  Future<String?> initiateManualDisbursement({
    required String channel,
    required double amount,
    required String phone,
    required String remarks,
    String? accountReference,
  }) async {
    final res = await _api.post('/admin/manual-disbursement/initiate', body: {
      'channel': channel,
      'amount': amount,
      'phone': phone,
      'remarks': remarks,
      if (accountReference != null) 'accountReference': accountReference,
    });
    final data = jsonDecode(res.body);
    return data['success'] == true ? data['data']['disbursementId'] : null;
  }

  Future<bool> confirmManualDisbursement(String disbursementId, String otp) async {
    final res = await _api.post('/admin/manual-disbursement/confirm', body: {
      'disbursementId': disbursementId,
      'otp': otp,
    });
    return jsonDecode(res.body)['success'] ?? false;
  }
}
