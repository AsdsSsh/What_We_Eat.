import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class DoDishPage extends StatefulWidget {
  const DoDishPage({super.key});

  @override
  State<DoDishPage> createState() => _DoDishPageState();
}

class _DoDishPageState extends State<DoDishPage>
    with TickerProviderStateMixin {
  // Available ingredients (改为动态，从数据库读取)
  List<String> _allIngredients = [];
  // 按类型分组的原材料
  Map<String, List<String>> _ingredientsByType = {};
  // Recipes with required ingredients（改为动态加载）
  Map<String, List<String>> _recipes = {};
  Set<String> _selectedIngredients = {};
  List<String> _matchedRecipes = [];
  late AnimationController _animationController;
  final Map<String, GlobalKey> _ingredientKeys = {};

  // 类型图标映射
  final Map<String, IconData> _typeIcons = {
    '蔬菜': Icons.eco_rounded,
    '肉类': Icons.kebab_dining_rounded,
    '调料': Icons.water_drop_rounded,
    '主食': Icons.rice_bowl_rounded,
    '海鲜': Icons.set_meal_rounded,
    '其他': Icons.category_rounded,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadIngredientsFromDb();
    _loadRecipesFromDb();
  }

  Future<void> _loadIngredientsFromDb() async {
    try {
      final rows = await FoodDatabaseHelper.instance.getAllRawMaterials();
      final names = rows
          .map((r) => (r['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      final Map<String, List<String>> grouped = {};
      for (final r in rows) {
        final name = (r['name'] as String?) ?? '';
        if (name.isEmpty) continue;
        final type = (r['type'] as String?) ?? '其他';
        grouped.putIfAbsent(type, () => []).add(name);
      }
      setState(() {
        _allIngredients = names;
        _ingredientsByType = grouped;
        _ingredientKeys.clear();
        for (var ingredient in _allIngredients) {
          _ingredientKeys[ingredient] = GlobalKey();
        }
        _updateMatchedRecipes();
      });
    } catch (e) {
      print('ERROR: 加载原材料异常: $e');
    }
  }

  Future<void> _loadRecipesFromDb() async {
    try {
      final List<Food> foods = await FoodDatabaseHelper.instance.getAllFoods();
      final Map<String, List<String>> map = {
        for (final f in foods) f.name: List<String>.from(f.ingredients)
      };
      setState(() {
        _recipes = map;
        _updateMatchedRecipes();
      });
    } catch (e) {
      print('ERROR: 加载菜谱异常: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
      _updateMatchedRecipes();
    });
  }

  void _updateMatchedRecipes() {
    if (_selectedIngredients.isEmpty) {
      _matchedRecipes = [];
      return;
    }
    _matchedRecipes = _recipes.entries
        .where((entry) {
          final requiredSet = Set<String>.from(entry.value);
          return _selectedIngredients.every((ingredient) => requiredSet.contains(ingredient));
        })
        .map((entry) => entry.key)
        .toList();
  }

  double _calcMatchPercent(List<String> requiredIngredients) {
    if (requiredIngredients.isEmpty) return 0;
    final matchedCount = requiredIngredients
        .where((ingredient) => _selectedIngredients.contains(ingredient))
        .length;
    return (matchedCount / requiredIngredients.length) * 100;
  }

  void _clearSelection() {
    setState(() {
      _selectedIngredients.clear();
      _matchedRecipes = [];
    });
  }

  void _randomMatch() {
    if (_allIngredients.isEmpty) return;
    final random = List<String>.from(_allIngredients)..shuffle();
    final count = 3 + (random.length % 3);
    setState(() {
      _selectedIngredients = Set.from(random.take(count));
      _updateMatchedRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部操作区域
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '食材烹饪',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择你手边的食材，发现美味菜谱',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _randomMatch,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.shuffle_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '随机匹配',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _clearSelection,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.clear_rounded,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '清空选择',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 已选食材计数
                  if (_selectedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '已选择 ${_selectedIngredients.length} 种食材',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 上半部分：食材选择区域
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ingredientsByType.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: AppTheme.primaryColor),
                                  const SizedBox(height: 16),
                                  Text(
                                    '加载食材中...',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _ingredientsByType.entries.map((entry) {
                              final type = entry.key;
                              final items = entry.value;
                              return _buildIngredientSection(context, type, items, isDark);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 下半部分：推荐菜品区域
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '推荐菜谱',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_matchedRecipes.length} 道',
                              style: TextStyle(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _matchedRecipes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedIngredients.isEmpty
                                        ? '选择食材以查看推荐菜谱'
                                        : '没有找到匹配的菜谱',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _matchedRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _matchedRecipes[index];
                                final requiredIngredients = _recipes[recipe] ?? [];
                                final matchPercentage =
                                    _calcMatchPercent(requiredIngredients).toStringAsFixed(0);
                                return _buildRecipeCard(
                                  context,
                                  recipe,
                                  requiredIngredients,
                                  matchPercentage,
                                  isDark,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSection(BuildContext context, String type, List<String> items, bool isDark) {
    final icon = _typeIcons[type] ?? Icons.category_rounded;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((ingredient) {
              final isSelected = _selectedIngredients.contains(ingredient);
              return GestureDetector(
                onTap: () => _toggleIngredient(ingredient),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  key: _ingredientKeys[ingredient],
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    String recipeName,
    List<String> requiredIngredients,
    String matchPercentage,
    bool isDark,
  ) {
    final matchPercent = double.tryParse(matchPercentage) ?? 0;
    final matchColor = matchPercent >= 80
        ? AppTheme.accentGreen
        : matchPercent >= 50
            ? AppTheme.accentOrange
            : AppTheme.primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailPage(recipeName: recipeName),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        recipeName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: matchColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_rounded,
                            size: 14,
                            color: matchColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchPercentage%',
                            style: TextStyle(
                              color: matchColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: requiredIngredients.take(6).map((ingredient) {
                    final isSelected = _selectedIngredients.contains(ingredient);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          Text(
                            ingredient,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (requiredIngredients.length > 6) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+${requiredIngredients.length - 6} 更多食材',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}