import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }


  Future _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        ingredients TEXT,
        steps TEXT
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
}