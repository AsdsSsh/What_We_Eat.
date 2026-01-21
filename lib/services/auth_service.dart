import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'authToken';

  static Future<String?> ensureAnonymousSession(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_tokenKey);
    if (cached?.isNotEmpty == true) return cached;

    final uri = Uri.parse('http://localhost:8080/api/user/register');
    final resp = await http
        .post(uri, body: jsonEncode({'deviceId': deviceId}), headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final token = jsonDecode(resp.body)['token'] as String?;
      if (token != null) {
        await prefs.setString(_tokenKey, token);
      }
      return token;
    }
    return null;
  }
}