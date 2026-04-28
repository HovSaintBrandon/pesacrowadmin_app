import 'dart:convert';
import 'api_service.dart';
import '../models/admin.dart';
import '../models/audit_log.dart';
import '../models/deal.dart';
import '../models/blacklist_item.dart';
import '../models/fee_config.dart';
import '../models/mpesa_balance.dart';
import '../models/mpesa_balance_snapshot.dart';
import '../models/user.dart';
import '../models/financial_stats.dart';
import '../models/system_config.dart';
import '../models/mpesa_query_log.dart';
import '../models/go_live_request.dart';
import '../models/platform.dart';


class AdminService {
  final ApiService _api = ApiService();
  ApiService get api => _api;
  bool get hasToken => _api.hasToken;

  String _extractError(dynamic data) {
    if (data is Map) {
      if (data['details'] is List && (data['details'] as List).isNotEmpty) {
        final details = data['details'] as List;
        final parts = details.map((d) => d['message']?.toString() ?? d.toString());
        return parts.join(', ');
      }
      return data['message']?.toString() ?? 'An unknown error occurred';
    }
    return data?.toString() ?? 'An unknown error occurred';
  }

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
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw Exception('UNAUTHORIZED');
      }
      final data = jsonDecode(res.body);
      
      final profileData = (data is Map && data['data'] != null) ? data['data'] : data;
      if (profileData is Map<String, dynamic>) {
        // Fetch dynamic permissions assigned to this current session
        try {
          final permRes = await _api.get('/admin/my-permissions');
          if (permRes.statusCode == 200) {
            final permData = jsonDecode(permRes.body);
            if (permData['data'] != null && permData['data']['permissions'] != null) {
              profileData['permissions'] = permData['data']['permissions'];
            }
          }
        } catch (e) {
          print('⚠️ AdminService: Could not map precise permissions: \$e');
        }

        return Admin.fromJson(profileData);
      }
    } catch (e) {
      print('❌ AdminService: Error fetching profile: \$e');
      if (e.toString().contains('UNAUTHORIZED')) {
        rethrow;
      }
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

  Future<String?> exportTransactions({String? fromDate, String? toDate, String? status}) async {
    final query = <String, String>{
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
      if (status != null) 'status': status,
    };
    final res = await _api.get('/admin/transactions/export', query: query);
    
    // Check if the response is CSV or JSON
    if (res.headers['content-type']?.contains('csv') == true || res.body.startsWith('transactionId')) {
      final bytes = utf8.encode(res.body);
      final base64String = base64.encode(bytes);
      return 'data:text/csv;base64,$base64String';
    }

    try {
      final data = jsonDecode(res.body);
      return data['success'] == true ? (data['data']['downloadUrl'] ?? data['data']) : null;
    } catch (e) {
      print('❌ AdminService: Failed to parse export response: $e');
      return null;
    }
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
      final innerData = data['data'];
      List rawList = [];
      if (innerData is List) {
        rawList = innerData;
      } else if (innerData is Map) {
        rawList = innerData['logs'] ?? [];
      }
      return rawList.map((e) => AuditLog.fromJson(e)).toList();
    }
    return [];
  }

  Future<String?> exportAuditLogs({String? fromDate, String? toDate}) async {
    final query = <String, String>{
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    };
    final res = await _api.get('/admin/audit-logs/export', query: query);
    
    // Check if the response is CSV or JSON
    if (res.headers['content-type']?.contains('csv') == true || res.body.startsWith('id,') || res.body.startsWith('action,')) {
      final bytes = utf8.encode(res.body);
      final base64String = base64.encode(bytes);
      return 'data:text/csv;base64,$base64String';
    }

    try {
      final data = jsonDecode(res.body);
      return data['success'] == true ? (data['data']['downloadUrl'] ?? data['data']) : null;
    } catch (e) {
      print('❌ AdminService: Failed to parse audit export response: $e');
      return null;
    }
  }

  Future<bool> deleteAuditLog(String id) async {
    final res = await _api.delete('/admin/audit-logs/$id');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> retryPayout(String transactionId) async {
    final res = await _api.post('/admin/deals/$transactionId/retry-payout');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> cancelDeal(String transactionId) async {
    final res = await _api.post('/deals/$transactionId/cancel');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> initiateRefund(String transactionId, String reason) async {
    final res = await _api.post('/admin/deals/$transactionId/refund', body: {'reason': reason});
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  // ─── DISPUTE RESOLUTION ───────────────────────────────────────────────────
  Future<bool> resolveDispute(String transactionId, String decision, String resolution) async {
    final res = await _api.post('/admin/resolve-dispute/$transactionId', body: {
      'decision': decision,
      'resolution': resolution,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> addDisputeNote(String transactionId, String note) async {
    final res = await _api.post('/admin/disputes/$transactionId/notes', body: {'note': note});
    return jsonDecode(res.body)['success'] ?? false;
  }

  Future<Map<String, dynamic>> getDisputeDetail(String transactionId) async {
    final res = await _api.get('/admin/disputes/$transactionId');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ─── BLACKLIST ────────────────────────────────────────────────────────────
  Future<bool> banPhone(String phone, String reason) async {
    final res = await _api.post('/admin/ban-phone', body: {'phone': phone, 'reason': reason});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> unbanPhone(String phone) async {
    final res = await _api.post('/admin/unban-phone', body: {'phone': phone});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<List<BlacklistItem>> getBlacklist() async {
    final res = await _api.get('/admin/blacklist');
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((b) => BlacklistItem.fromJson(b)).toList();
    }
    return [];
  }

  // ─── USER MANAGEMENT ─────────────────────────────────────────────────────
  Future<AppUser?> lookupUser(String phone) async {
    final res = await _api.get('/admin/users/$phone');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      return AppUser.fromJson(data['data']);
    }
    return null;
  }

  Future<bool> freezeAccount(String phone, String reason) async {
    final res = await _api.post('/admin/users/$phone/freeze', body: {'reason': reason});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> unfreezeAccount(String phone) async {
    final res = await _api.delete('/admin/users/$phone/freeze');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<List<AppUser>> listFrozenAccounts() async {
    final res = await _api.get('/admin/users/frozen');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List).map((u) => AppUser.fromJson(u)).toList();
    }
    return [];
  }

  // ─── ADMIN MANAGEMENT ────────────────────────────────────────────────────
  Future<bool> createAdmin(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/create', body: body);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return true;
    }
    throw Exception(data['message'] ?? 'An unknown error occurred');
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
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    final res = await _api.post('/admin/update-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> deleteAdmin(String id) async {
    final res = await _api.delete('/admin/$id');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<List<String>> getAllPermissions() async {
    final res = await _api.get('/admin/permissions');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List).map((p) {
        if (p is Map) return p['key']?.toString() ?? p.toString();
        return p.toString();
      }).toList();
    }
    return [];
  }

  // ─── M-PESA TOOLS ─────────────────────────────────────────────────────────
  Future<bool> registerC2B() async {
    final res = await _api.post('/admin/mpesa/c2b/register');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> simulateC2B(double amount, String msisdn, String billRef) async {
    final res = await _api.post('/admin/mpesa/c2b/simulate', body: {
      'amount': amount,
      'msisdn': msisdn,
      'billRefNumber': billRef,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> triggerReversal(String transactionId, String remarks) async {
    final res = await _api.post('/admin/transactions/$transactionId/reversal', body: {'remarks': remarks});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
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
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> queryBalance(String remarks) async {
    final res = await _api.post('/admin/mpesa/balance/query', body: {'remarks': remarks});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
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
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> queryMpesaReceipt(String receipt) async {
    final res = await _api.get('/admin/mpesa/query/$receipt');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<Map<String, dynamic>> getMpesaQueryLogs({int page = 1, int limit = 50, String? identifier}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (identifier != null && identifier.isNotEmpty) 'identifier': identifier,
    };
    final res = await _api.get('/admin/mpesa/status/logs', query: query);
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final innerData = data['data'];
      List rawList = [];
      int total = 0;
      if (innerData is List) {
        rawList = innerData;
        total = data['total'] ?? rawList.length;
      } else if (innerData is Map) {
        rawList = innerData['logs'] ?? innerData['data'] ?? [];
        total = (innerData['total'] ?? data['total'] ?? rawList.length).toInt();
      }
      return {
        'logs': rawList.map((e) => MpesaQueryLog.fromJson(e)).toList(),
        'total': total,
      };
    }
    return {'logs': <MpesaQueryLog>[], 'total': 0};
  }

  Future<bool> registerPullTransactions({
    required String nominatedNumber,
    required String callbackUrl,
  }) async {
    final res = await _api.post('/admin/mpesa/pull/register', body: {
      'nominatedNumber': nominatedNumber,
      'callbackUrl': callbackUrl,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
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
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  // ─── MANUAL DISBURSEMENT ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> initiateManualDisbursement({
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
    if (data['success'] == true) return data['data'];
    throw Exception(_extractError(data));
  }

  Future<Map<String, dynamic>?> initiateCompanyDisbursement({
    required String channel,
    required double amount,
    required String phone,
    required String remarks,
    String? accountReference,
  }) async {
    final res = await _api.post('/admin/company-disbursement/initiate', body: {
      'channel': channel,
      'amount': amount,
      'phone': phone,
      'remarks': remarks,
      if (accountReference != null) 'accountReference': accountReference,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return data['data'];
    throw Exception(_extractError(data));
  }

  Future<bool> confirmManualDisbursement(String disbursementId, String otp) async {
    final res = await _api.post('/admin/manual-disbursement/confirm', body: {
      'disbursementId': disbursementId,
      'otp': otp,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  // ─── ANNOUNCEMENTS ───────────────────────────────────────────────────────
  Future<bool> sendAnnouncement({required String target, required String message, required String via}) async {
    final res = await _api.post('/admin/announcements', body: {
      'target': target,
      'message': message,
      'via': via,
    });
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  // ─── FINANCIAL STATISTICS ────────────────────────────────────────────────
  Future<FinancialStats?> getFinancialStats() async {
    final res = await _api.get('/admin/financials/stats');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      return FinancialStats.fromJson(data['data']);
    }
    return null;
  }

  // ─── SYSTEM CONFIGURATION & HEALTH ──────────────────────────────────────
  Future<WebhookConfig?> getWebhookConfig() async {
    final res = await _api.get('/admin/config/webhooks');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      return WebhookConfig.fromJson(data['data']);
    }
    return null;
  }

  Future<bool> updateWebhookConfig(Map<String, dynamic> delta) async {
    final res = await _api.patch('/admin/config/webhooks', body: delta);
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<OtpConfig?> getOtpConfig() async {
    final res = await _api.get('/admin/config/otp');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      return OtpConfig.fromJson(data['data']);
    }
    return null;
  }

  Future<bool> updateOtpConfig(Map<String, dynamic> delta) async {
    final res = await _api.patch('/admin/config/otp', body: delta);
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<SystemHealth?> getSystemHealth() async {
    final res = await _api.get('/admin/system/health');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] != null) {
      return SystemHealth.fromJson(data['data']);
    }
    return null;
  }

  // ─── PLATFORM MANAGEMENT ────────────────────────────────────────────────
  Future<List<GoLiveRequest>> getGoLiveRequests() async {
    final res = await _api.get('/admin/go-live-requests');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List).map((r) => GoLiveRequest.fromJson(r)).toList();
    }
    return [];
  }

  Future<bool> approveGoLiveRequest(String id) async {
    final res = await _api.post('/admin/go-live-requests/$id/approve');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> rejectGoLiveRequest(String id, String reason) async {
    final res = await _api.post('/admin/go-live-requests/$id/reject', body: {'reason': reason});
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<List<Platform>> getPlatforms() async {
    final res = await _api.get('/admin/platforms');
    final data = jsonDecode(res.body);
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List).map((p) => Platform.fromJson(p)).toList();
    }
    return [];
  }

  Future<bool> togglePlatformFreeze(String id) async {
    final res = await _api.post('/admin/platforms/$id/freeze');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> rotatePlatformKey(String id) async {
    final res = await _api.post('/admin/platforms/$id/rotate-key');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> updatePlatform(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/platforms/$id', body: body);
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }

  Future<bool> deletePlatform(String id) async {
    final res = await _api.delete('/admin/platforms/$id');
    final data = jsonDecode(res.body);
    if (data['success'] == true) return true;
    throw Exception(_extractError(data));
  }
}
