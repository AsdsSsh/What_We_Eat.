import 'dart:convert';



/// @description: 食物类
class Food {
  String id;
  String name;
  String description;
  List<String> ingredients;
  List<String> steps;
  List<String> nutritionTags;


  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    List<String>? nutritionTags,
  }) : nutritionTags = nutritionTags ?? <String>[];


  factory Food.fromMap(Map<String, dynamic> map) {
    final rawTags = map['nutritionTags'];
    List<String> decodedTags = [];
    if (rawTags is String && rawTags.isNotEmpty) {
      decodedTags = List<String>.from(jsonDecode(rawTags));
    } else if (rawTags is List) {
      decodedTags = List<String>.from(rawTags);
    }

    return Food(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      ingredients: map['ingredients'] != null
          ? List<String>.from(jsonDecode(map['ingredients'] as String))
          : [],
      steps: map['steps'] != null
          ? List<String>.from(jsonDecode(map['steps'] as String))
          : [],
      nutritionTags: decodedTags,
    );
  }

  Map<String , dynamic> toMap() {
      return {
        'id': id,
        'name': name,
        'description': description,
        'ingredients': jsonEncode(ingredients),
        'steps': jsonEncode(steps),
        'nutritionTags': jsonEncode(nutritionTags),
      };
    }

}