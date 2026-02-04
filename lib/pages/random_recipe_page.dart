import 'dart:math';
import 'package:flutter/material.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class RandomRecipePage extends StatefulWidget {
  const RandomRecipePage({super.key});

  @override
  State<RandomRecipePage> createState() => _RandomRecipePageState();
}

class _RandomRecipePageState extends State<RandomRecipePage> {
  int _recipeCount = 3;
  double _budget = 50;
  List<Map<String, dynamic>> _randomRecipes = [];
  bool _hasGenerated = false;

  // 假数据
  final List<Map<String, dynamic>> _allRecipes = [
    {'name_zh': '番茄炒蛋', 'name_en': 'Tomato Scrambled Eggs', 'price': 15},
    {'name_zh': '红烧排骨', 'name_en': 'Braised Pork Ribs', 'price': 45},
    {'name_zh': '清炒时蔬', 'name_en': 'Stir-fried Vegetables', 'price': 12},
    {'name_zh': '宫保鸡丁', 'name_en': 'Kung Pao Chicken', 'price': 28},
    {'name_zh': '麻婆豆腐', 'name_en': 'Mapo Tofu', 'price': 18},
    {'name_zh': '糖醋里脊', 'name_en': 'Sweet and Sour Pork', 'price': 35},
    {'name_zh': '酸辣土豆丝', 'name_en': 'Shredded Potatoes', 'price': 10},
    {'name_zh': '鱼香肉丝', 'name_en': 'Yu Xiang Pork', 'price': 25},
    {'name_zh': '蒜蓉西兰花', 'name_en': 'Garlic Broccoli', 'price': 14},
    {'name_zh': '回锅肉', 'name_en': 'Twice-cooked Pork', 'price': 30},
  ];

  String get _lang => appLanguageNotifier.value;

  String t(String key) => Translations.translate(key, _lang);

  void _generateRandomRecipes() {
    final random = Random();
    final filteredRecipes = _allRecipes.where((r) => r['price'] <= _budget).toList();
    
    if (filteredRecipes.isEmpty) {
      setState(() {
        _randomRecipes = [];
        _hasGenerated = true;
      });
      return;
    }

    filteredRecipes.shuffle(random);
    setState(() {
      _randomRecipes = filteredRecipes.take(_recipeCount).toList();
      _hasGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_lang == 'zh' ? '随机菜谱' : 'Random Recipes'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设置区域
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lang == 'zh' ? '随机设置' : 'Random Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 数量选择
                      Text(
                        _lang == 'zh' ? '菜谱数量: $_recipeCount 道' : 'Recipe Count: $_recipeCount',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      Slider(
                        value: _recipeCount.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _recipeCount = value.toInt();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 预算选择
                      Text(
                        _lang == 'zh' ? '预算上限: ¥${_budget.toInt()}' : 'Budget Limit: ¥${_budget.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      Slider(
                        value: _budget,
                        min: 10,
                        max: 200,
                        divisions: 19,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _budget = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 生成按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _generateRandomRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _lang == 'zh' ? '开始随机' : 'Generate Random',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 结果展示
                if (_hasGenerated) ...[
                  Text(
                    _lang == 'zh' ? '随机结果' : 'Random Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_randomRecipes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        _lang == 'zh' ? '没有符合预算的菜谱，请提高预算' : 'No recipes within budget, please increase budget',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    )
                  else
                    ...List.generate(_randomRecipes.length, (index) {
                      final recipe = _randomRecipes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _lang == 'zh' ? recipe['name_zh'] : recipe['name_en'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '¥${recipe['price']}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
