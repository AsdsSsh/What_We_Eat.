import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class DoDishPage extends StatefulWidget {
  const DoDishPage({super.key});

  @override
  State<DoDishPage> createState() => _DoDishPageState();
}

class _DoDishPageState extends State<DoDishPage> with TickerProviderStateMixin {
  List<String> _allIngredients = [];
  // 按类型分组的原材料
  Map<String, List<String>> _ingredientsByType = {};
  Map<String, Food> _foodMap = {};
  Set<String> _selectedIngredients = {};
  List<String> _matchedRecipes = [];
  late AnimationController _animationController;
  final Map<String, GlobalKey> _ingredientKeys = {};
  String _selectedLanguage = 'zh';
  // 类型图标映射
  final Map<String, IconData> _typeIcons = {
    '蔬菜': Icons.eco_rounded,
    '肉类': Icons.kebab_dining_rounded,
    '调料': Icons.water_drop_rounded,
    '主食': Icons.rice_bowl_rounded,
    '海鲜': Icons.set_meal_rounded,
    '其他': Icons.category_rounded,
  };

  bool _compactIngredients = true; // 紧凑模式开关（默认开启）

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
    _initLanguageFromPrefs();
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
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
      final Map<String, Food> foodMap = {for (final f in foods) f.name: f};
      setState(() {
        _foodMap = foodMap;
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
    _matchedRecipes = _foodMap.entries
        .where((entry) {
          final requiredSet = Set<String>.from(entry.value.ingredients);
          return _selectedIngredients
              .every((ingredient) => requiredSet.contains(ingredient));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
        valueListenable: appLanguageNotifier,
        builder: (context, lang, child) {
          _selectedLanguage = lang;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // 上半部分：食材选择区域
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                        child: Column(
                          children: [
                            // 新增：固定头部（不随滚动）
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    '布局',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _compactIngredients ? '紧凑' : '常规',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_selectedIngredients.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '已选 ${_selectedIngredients.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  Switch(
                                    value: _compactIngredients,
                                    onChanged: (v) => setState(() => _compactIngredients = v),
                                    activeThumbColor: AppTheme.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // 原滚动区域改为 Expanded
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_ingredientsByType.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32),
                                          child: Column(
                                            children: [
                                              CircularProgressIndicator(
                                                  color: AppTheme.primaryColor),
                                              const SizedBox(height: 16),
                                              Text(
                                                t('Loading'),
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.textSecondaryDark
                                                      : AppTheme.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 类型分组渲染
                                          ..._ingredientsByType.entries.map((entry) {
                                            final type = entry.key;
                                            final items = entry.value;
                                            return _buildIngredientSection(context, type, items, isDark);
                                          }).toList(),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                        color: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
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
                                      t('RecommendedRecipes'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppTheme.textPrimaryDark
                                            : AppTheme.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen
                                        .withValues(alpha: 0.1),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 56,
                                          color: isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _selectedIngredients.isEmpty
                                              ? t('SelectIngredientsSubtitle')
                                              : t('NoMatchingRecipes'),
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.textSecondaryDark
                                                : AppTheme.textSecondaryLight,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    itemCount: _matchedRecipes.length,
                                    itemBuilder: (context, index) {
                                      final recipe = _matchedRecipes[index];
                                      final food = _foodMap[recipe];
                                      final requiredIngredients =
                                          food?.ingredients ?? [];
                                      final matchPercentage =
                                          _calcMatchPercent(requiredIngredients)
                                              .toStringAsFixed(0);
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
        });
  }

  Widget _buildIngredientSection(
      BuildContext context, String type, List<String> items, bool isDark) {
    final icon = _typeIcons[type] ?? Icons.category_rounded;
    final selectedInType =
        items.where((i) => _selectedIngredients.contains(i)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：类型 + 统计
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '已选 $selectedInType / 共 ${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 紧凑模式：AnimatedContainer 的 BoxDecoration
          if (_compactIngredients)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // 目标卡片宽约 120，最少2列，最多6列
                final crossAxisCount = (width / 120).floor().clamp(2, 6);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    // 横向长条比例更紧凑
                    childAspectRatio: 3.6,
                  ),
                  itemBuilder: (context, idx) {
                    final ingredient = items[idx];
                    final isSelected =
                        _selectedIngredients.contains(ingredient);
                    return GestureDetector(
                      onTap: () => _toggleIngredient(ingredient),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        key: _ingredientKeys[ingredient],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                    isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            width: 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            ingredient,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            )
          // 常规模式：AnimatedContainer 的 BoxDecoration
          else
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
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
            final food = _foodMap[recipeName];
            if (food != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipeInfo: food),
                ),
              );
            }
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
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                    final isSelected =
                        _selectedIngredients.contains(ingredient);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200),
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
                                  : (isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
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
