import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:what_we_eat/models/favorite_food.dart';
import 'package:what_we_eat/models/food.dart';
import 'dart:convert';

class FoodDatabaseHelper {
  static final FoodDatabaseHelper instance  = FoodDatabaseHelper._init();
  static Database? _database;


  FoodDatabaseHelper._init();


  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('food_database.db');
    return _database!;
  }


   Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }


  Future _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        ingredients TEXT,
        steps TEXT,
        nutritionTags TEXT

      )
    ''');
    // 新增原材料表
    await db.execute('''
      CREATE TABLE raw_materials(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT
      )
    ''');
    await db.execute('''
     CREATE TABLE favorite_foods(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT
      )
    ''');

    // 从json 文件中初始化数据到数据库 - 菜谱
    try {
      final data = await rootBundle.loadString('assets/data/foods.json');
      final List<dynamic> jsonList = json.decode(data);
      for (var item in jsonList) {
        final food = Food(
          id : item['id'] as String,
          name: item['name'] as String,
          description: item['description'] as String,
          ingredients: List<String>.from(item['ingredients']),
          steps: List<String>.from(item['steps']),
          nutritionTags: item['nutritionTags'] != null
              ? List<String>.from(item['nutritionTags'])
              : <String>[],
        );
        await db.insert('foods', food.toMap());
        print('初始化 ${jsonList.length} 条菜谱');
      }
    } catch (e) {
      print('❌ 初始化失败: $e');
    }

    // 从json 文件中初始化数据到数据库 - 原材料
    try {
      final rmData = await rootBundle.loadString('assets/data/raw_material.json');
      final List<dynamic> rmList = json.decode(rmData);
      for (var item in rmList) {
        final map = {
          'id': item['id'] as String,
          'name': item['name'] as String,
          'type': item['type'] as String,
        };
        await db.insert('raw_materials', map);
      }
      print('初始化 ${rmList.length} 条食材');
    } catch (e) {
      print('❌ 初始化失败: $e');
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(foods)');
      final hasNutritionTags = tableInfo.any(
        (row) => row['name'] == 'nutritionTags',
      );
      if (!hasNutritionTags) {
        await db.execute('ALTER TABLE foods ADD COLUMN nutritionTags TEXT');
      }
    }
  }


  // --- CRUD 操作 ---

  Future<int> createFood(Food food) async {
    final db = await database;
    return await db.insert('foods', food.toMap());
  }

  Future<List<Food>> getAllFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foods');
    return List.generate(maps.length, (i) => Food.fromMap(maps[i]));
  }

  Future<Food?> getFoodById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Food.fromMap(maps.first);
    }
    return null;
  }


  Future<int> updateFood(Food food) async {
    final db = await database;
    return await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> deleteFood(String id) async {
    final db = await database;
    return await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 分页获取菜谱
  /// [limit] 每页数量
  /// [offset] 偏移量
  Future<List<Food>> getFoodsPaginated(int limit, int offset) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => Food.fromMap(maps[i]));
  }

  /// 获取菜谱总数
  Future<int> getFoodsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM foods');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 原材料查询：确保表存在并返回全部原材料行
  Future<List<Map<String, dynamic>>> getAllRawMaterials() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_materials(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT
      )
    ''');
    return await db.query('raw_materials');
  }

  /// 收藏菜谱相关操作
  Future<void> addFavoriteFood(Food food) async {
    final db = await database;
    final favoriteFood = FavoriteFood(
      id: food.id,
      name: food.name,
      description: food.description,
    );
    await db.insert(
      'favorite_foods',
      favoriteFood.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavoriteFood(String id) async {
    final db = await database;
    await db.delete(
      'favorite_foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FavoriteFood>> getFavoriteFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorite_foods');
    return List.generate(maps.length, (i) => FavoriteFood.fromMap(maps[i]));
  }


  Future<bool> isFoodFavorited(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_foods',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty;
  }


  Future<void> changeLove(Food food , bool targetChangeState) async {
    if (targetChangeState) {
      addFavoriteFood(food);
    } else {
      removeFavoriteFood(food.id);
    }
  }


  

  /// 收藏菜谱相关操作 结束
}