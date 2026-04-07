import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _adminToken;
  bool get hasToken => _adminToken != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminToken = prefs.getString('admin_token');
    if (_adminToken != null) {
      print('🔑 ApiService: Loaded persisted token');
    }
  }

  Future<void> setToken(String token) async {
    _adminToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_token', token);
    print('🔑 ApiService: Token updated and persisted');
  }

  Future<void> clearToken() async {
    _adminToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    print('🔑 ApiService: Token cleared from persistence');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
      };

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(queryParameters: query);
    _logRequest('GET', uri.toString());
    final res = await http.get(uri, headers: _headers);
    _logResponse('GET', uri.toString(), res);
    return res;
  }

  Future<http.Response> post(String path, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    _logRequest('POST', uri.toString(), body: body);
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body ?? {}));
    _logResponse('POST', uri.toString(), res);
    return res;
  }

  Future<http.Response> patch(String path, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    _logRequest('PATCH', uri.toString(), body: body);
    final res = await http.patch(uri, headers: _headers, body: jsonEncode(body ?? {}));
    _logResponse('PATCH', uri.toString(), res);
    return res;
  }

  Future<http.Response> delete(String path, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    _logRequest('DELETE', uri.toString(), body: body);
    final res = await http.delete(uri, headers: _headers, body: jsonEncode(body ?? {}));
    _logResponse('DELETE', uri.toString(), res);
    return res;
  }

  void _logRequest(String method, String url, {dynamic body}) {
    print('🚀 [API REQ] $method $url');
    if (body != null) print('📦 Body: ${jsonEncode(body)}');
  }

  void _logResponse(String method, String url, http.Response res) {
    final status = res.statusCode;
    final icon = status >= 200 && status < 300 ? '✅' : '❌';
    print('$icon [API RES] $status $method $url');
    if (res.body.isNotEmpty) {
      final body = res.body.length > 500 ? '${res.body.substring(0, 500)}...' : res.body;
      print('💾 Response: $body');
    }
  }
}
