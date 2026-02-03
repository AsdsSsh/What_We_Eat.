import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userName;
  String? _userId;
  String? _email;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userName => _userName;
  String? get userId => _userId;
  String? get email => _email;

  // 初始化时检查本地是否有保存的登录状态
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userName = prefs.getString('userName');
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    
    // 调试日志
    debugPrint('=== checkLoginStatus ===');
    debugPrint('token: $_token');
    debugPrint('email: $_email');
    debugPrint('userName: $_userName');
    debugPrint('isLoggedIn: $_isLoggedIn');
    
    notifyListeners();
  }

  // 登录成功后保存状态
  Future<void> login(String token, String email, {required String userName}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 确保数据被正确保存
    final tokenSaved = await prefs.setString('token', token);
    final emailSaved = await prefs.setString('email', email);
    final userNameSaved = await prefs.setString('userName', userName);
    
    // 调试日志
    debugPrint('=== login ===');
    debugPrint('tokenSaved: $tokenSaved, token: $token');
    debugPrint('emailSaved: $emailSaved, email: $email');
    debugPrint('userNameSaved: $userNameSaved, userName: $userName');
    
    _token = token;
    _email = email;
    _userName = userName;
    _isLoggedIn = true;
    notifyListeners();
  }

  // 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('userName');
    await prefs.remove('userId');
    
    _token = null;
    _email = null;
    _userName = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateUserName(String userName) async {
    _userName = userName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    notifyListeners();
  }
}