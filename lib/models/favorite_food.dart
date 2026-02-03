


class FavoriteFood {
  String id;
  String name;
  String description;
  FavoriteFood({
    required this.id,
    required this.name,
    required this.description,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }


  factory FavoriteFood.fromMap(Map<String, dynamic> map) {
    return FavoriteFood(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }
}