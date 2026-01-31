import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _phone;
  String? _userName;
  String? _userId;
  String? _email;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get phone => _phone;
  String? get userName => _userName;
  String? get userId => _userId;
  String? get email => _email;

  // 初始化时检查本地是否有保存的登录状态
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _phone = prefs.getString('phone');
    _userName = prefs.getString('userName');
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    notifyListeners();
  }

  // 登录成功后保存状态
  Future<void> login(String token, String phone, {required String userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('phone', phone);
    await prefs.setString('userName', userName);
    
    _token = token;
    _phone = phone;
    _isLoggedIn = true;
    notifyListeners();
  }

  // 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('phone');
    
    _token = null;
    _phone = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateUserName(String userName) {
    _userName = userName;
  }
}