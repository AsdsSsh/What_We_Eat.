import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/config/api_config.dart';
import 'package:what_we_eat/config/app_config.dart';
import 'package:what_we_eat/database/food_database_helper.dart';

class AuthService {

  static const Duration _defaultSyncInterval = Duration(minutes: AppConfig.favoriteSyncIntervalMinutes);
  static Timer? _favoriteSyncTimer;
  static bool _isSynchronizing = false;


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
    if (_isSynchronizing) return;
    _isSynchronizing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 首先检查是否登录,如果未登录则不进行同步
      if (token == null || token.isEmpty) return;

      final favorites = await FoodDatabaseHelper.instance.getFavoriteFoods();
      final payload = {
        'token': token,
        'favorites': favorites.map((item) => item.id).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/favorite/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Failed to sync favorites: ${response.statusCode} ${response.body}',
        );
      }
    } finally {
      _isSynchronizing = false;
    }
  }

  static Future<void> _synchronizeFavoriteSafely() async {
    try {
      await synchronizeFavorite();
    } catch (e) {
      debugPrint('Favorite sync error: $e');
    }
  }

  static void startFavoriteSyncTimer({Duration interval = _defaultSyncInterval}) {
    stopFavoriteSyncTimer();
    _synchronizeFavoriteSafely();
    _favoriteSyncTimer = Timer.periodic(interval, (_) {
      _synchronizeFavoriteSafely();
    });
  }

  static void stopFavoriteSyncTimer() {
    _favoriteSyncTimer?.cancel();
    _favoriteSyncTimer = null;
  }

  /// 从服务器拉取用户收藏列表并存入本地 SQLite
  static Future<void> fetchAndStoreFavorites({required String userId, required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/favorite/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> foodIds = [];

        // 兼容两种返回格式：直接数组 或 { "favorites": [...] }
        if (data is List) {
          foodIds = data.map((e) => e.toString()).toList();
        } else if (data is Map) {
          final list = data['favorites'] ?? data['data'] ?? [];
          if (list is List) {
            foodIds = list.map((e) {
              if (e is Map) return (e['id'] ?? e['foodId'] ?? '').toString();
              return e.toString();
            }).toList();
          }
        }

        await FoodDatabaseHelper.instance.replaceAllFavoritesFromIds(foodIds);
        debugPrint('Fetched and stored ${foodIds.length} favorites from server');
      } else {
        debugPrint(
          'Failed to fetch favorites: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }


}