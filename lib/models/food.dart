import 'dart:convert';



/// @description: 食物类
class Food {
  String id;
  String name;
  String description;
  List<String> ingredients;
  List<String> steps;
  List<String> nutritionTags;
  double budget;


  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    List<String>? nutritionTags,
    this.budget = 0,
  }) : nutritionTags = nutritionTags ?? <String>[];


  factory Food.fromJson(Map<String, dynamic> json) => Food.fromMap(json);


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
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
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
        'budget': budget,
      };
    }

}