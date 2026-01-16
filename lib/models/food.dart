import 'dart:convert';



/// @description: 食物类
class Food {
  String id;
  String name;
  String description;
  List<String> ingredients;
  List<String> steps;


  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps
  });


  factory Food.fromMap(Map<String, dynamic> map) {
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
    );
  }

  Map<String , dynamic> toMap() {
      return {
        'id': id,
        'name': name,
        'description': description,
        'ingredients': jsonEncode(ingredients),
        'steps': jsonEncode(steps),
      };
    }

}