import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:what_we_eat/config/api_config.dart';

class AuthService {


  static Future<void> getVerificationCode({required String email}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/login_or_register?email=$email'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to login or register');
    }
  }


  static Future<Map<String , dynamic>> loginWithCode({required String email, required String code}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/verify_code'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception('Failed to verify code');
    }
  }



  // 定期同步用户收藏数据到服务器
  static Future<void> synchronizeFavorite() async {
    //TODO 定期同步用户收藏数据到服务器
    // 首先检查是否登录,如果未登录则不进行同步


    //
  }


}