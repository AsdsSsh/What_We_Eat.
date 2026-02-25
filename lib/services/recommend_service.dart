import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:what_we_eat/config/api_config.dart';
import 'package:what_we_eat/models/food.dart';

class RecommendService {
  // AI Recommendation
  static Future<String> getAIRecommendations(
      {required String message,
      String? userId,
      double? lon,
      double? lat}) async {
    if (lon == null || lat == null) {
      // 如果为空，则使用默认位置（保定市）
      lon = 115.490696;
      lat = 38.8579735;
    }
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/recommend?call_ai'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(
          {'message': message, 'userId': userId, 'lon': lon, 'lat': lat}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<dynamic, dynamic>;
      final String answerResponse = data['response'] as String;
      return answerResponse;
    } else {
      throw Exception('Failed to fetch AI recommendations');
    }
  }

  static Future<List<Food>> getRecommendFoods({String? userId}) async {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;
    final hour = now.hour;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/recommend/basic_recommend?month=$month&day=$day&hour=$hour'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<dynamic, dynamic>;
      final foodsData = data['recommendations'] as List<dynamic>? ?? <dynamic>[];
      return foodsData.map((food) {
        final map = Map<String, dynamic>.from(food as Map);
        return Food(
          id: (map['id'] ?? map['foodId'] ?? '').toString(),
          name: map['name']?.toString() ?? '',
          description: map['description']?.toString() ?? '',
          ingredients: _asStringList(map['ingredients']),
          steps: _asStringList(map['steps']),
          nutritionTags: _asStringList(map['nutritionTags'] ?? map['tags']),
          budget: (map['budget'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch recommended foods');
    }
  }
}

List<String> _asStringList(dynamic value) {
  if (value == null) return <String>[];
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = json.decode(value);
      if (decoded is List) {
        return decoded
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // ignore and fall through
    }
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return <String>[];
}
