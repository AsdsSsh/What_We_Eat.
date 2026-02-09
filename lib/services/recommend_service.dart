import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:what_we_eat/config/api_config.dart';


class RecommendService {



  // AI Recommendation
  static Future<String> getAIRecommendations({
    required String message , String? userId ,
  double? lon , double? lat}) async {
    if (lon == null || lat == null) {
      // 如果为空，则使用默认位置（保定市）
      lon = 115.490696;
      lat = 38.8579735;
    }
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/recommend?call_ai'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({'message': message, 'userId': userId, 'lon': lon, 'lat': lat}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<dynamic, dynamic>;
      final String answerResponse = data['response'] as String;
      return answerResponse;
    } else {
      throw Exception('Failed to fetch AI recommendations');
    }
  }
}