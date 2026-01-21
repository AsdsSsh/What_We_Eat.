import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/pages/splash_screen.dart';
import 'package:what_we_eat/pages/setting_page.dart' show appThemeModeNotifier;
import 'package:what_we_eat/services/device_id.dart';
import 'package:what_we_eat/services/auth_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('darkModeEnabled') ?? false;
  appThemeModeNotifier.value = savedDark ? ThemeMode.dark : ThemeMode.light;

  // 获取或创建设备唯一标识符
  final deviceId = await getOrCreateDeviceId();
  
  runApp(MyApp(deviceId: deviceId));
  // 异步确保匿名会话，不阻塞主线程
  unawaited(
    AuthService.ensureAnonymousSession(deviceId).catchError((e, st) {
      print('匿名注册失败: $e');
      return null;
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key , required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          themeMode: mode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.grey[300],
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.grey[900],
            cardColor: Colors.grey[850],
          ),
        );
      },
    );
  }
}