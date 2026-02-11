import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// 自定义页面过渡
// ---------------------------------------------------------------------------
class _SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  _SlideFadeRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

class DoDishPage extends StatefulWidget {
  const DoDishPage({super.key});

  @override
  State<DoDishPage> createState() => _DoDishPageState();
}

class _DoDishPageState extends State<DoDishPage> with TickerProviderStateMixin {
  List<String> _allIngredients = [];
  Map<String, List<String>> _ingredientsByType = {};
  Map<String, Food> _foodMap = {};
  Set<String> _selectedIngredients = {};
  List<String> _matchedRecipes = [];
  final Map<String, GlobalKey> _ingredientKeys = {};
  String _selectedLanguage = 'zh';

  // 类型图标 & 颜色映射
  final Map<String, IconData> _typeIcons = {
    '蔬菜': Icons.eco_rounded,
    '肉类': Icons.kebab_dining_rounded,
    '调料': Icons.water_drop_rounded,
    '主食': Icons.rice_bowl_rounded,
    '海鲜': Icons.set_meal_rounded,
    '其他': Icons.category_rounded,
  };

  final Map<String, Color> _typeColors = {
    '蔬菜': const Color(0xFF34C759),
    '肉类': const Color(0xFFFF6B6B),
    '调料': const Color(0xFFFFBE0B),
    '主食': const Color(0xFFFF9500),
    '海鲜': const Color(0xFF4FACFE),
    '其他': const Color(0xFFA18CD1),
  };

  bool _compactIngredients = true;

  // ---- 动画控制器 ----
  late AnimationController _entryController;
  late Animation<double> _topPanelSlide;
  late Animation<double> _topPanelFade;
  late Animation<double> _bottomPanelSlide;
  late Animation<double> _bottomPanelFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadIngredientsFromDb();
    _loadRecipesFromDb();
    _initLanguageFromPrefs();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _topPanelSlide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    ));
    _topPanelFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    ));

    _bottomPanelSlide =
        Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));
    _bottomPanelFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _entryController.forward();
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() => _selectedLanguage = saved);
    appLanguageNotifier.value = saved;
  }

  String t(String key) => Translations.translate(key, _selectedLanguage);

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
      debugPrint('ERROR: 加载原材料异常: $e');
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
      debugPrint('ERROR: 加载菜谱异常: $e');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
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

  void _clearSelection() {
    setState(() {
      _selectedIngredients.clear();
      _updateMatchedRecipes();
    });
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
        valueListenable: appLanguageNotifier,
        builder: (context, lang, child) {
          _selectedLanguage = lang;
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A1A2E),
                          Color(0xFF16213E),
                          Color(0xFF0F3460),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0F4FF),
                          Color(0xFFE8F0FE),
                          Color(0xFFFFF3E6),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
              ),
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, _) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        // ---- 上半部分：食材选择 ----
                        Expanded(
                          flex: 1,
                          child: Transform.translate(
                            offset: Offset(0, _topPanelSlide.value),
                            child: Opacity(
                              opacity: _topPanelFade.value,
                              child: _buildIngredientsPanel(isDark),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ---- 下半部分：推荐菜品 ----
                        Expanded(
                          flex: 1,
                          child: Transform.translate(
                            offset: Offset(0, _bottomPanelSlide.value),
                            child: Opacity(
                              opacity: _bottomPanelFade.value,
                              child: _buildRecipesPanel(isDark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        });
  }

  // =====================================================================
  //  食材选择面板 — 玻璃态
  // =====================================================================
  Widget _buildIngredientsPanel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor
                      .withValues(alpha: isDark ? 0.1 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ---- 固定头部 ----
                _buildIngredientsHeader(isDark),

                // 分隔线
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                ),

                // ---- 滚动区域 ----
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ingredientsByType.isEmpty)
                          _buildLoadingState(isDark)
                        else
                          ..._ingredientsByType.entries.map((entry) {
                            return _buildIngredientSection(
                                context, entry.key, entry.value, isDark);
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- 食材面板头部 ----
  Widget _buildIngredientsHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
      child: Row(
        children: [
          // 渐变图标
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.kitchen_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            _selectedLanguage == 'zh' ? '选择食材' : 'Pick Ingredients',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 8),
          // 已选数量胶囊
          if (_selectedIngredients.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedIngredients.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          // 清空按钮
          if (_selectedIngredients.isNotEmpty)
            GestureDetector(
              onTap: _clearSelection,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all_rounded,
                        size: 14, color: AppTheme.accentRed),
                    const SizedBox(width: 4),
                    Text(
                      _selectedLanguage == 'zh' ? '清空' : 'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 6),
          // 布局切换
          _buildLayoutToggle(isDark),
        ],
      ),
    );
  }

  Widget _buildLayoutToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _compactIngredients = !_compactIngredients),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _compactIngredients
              ? Icons.grid_view_rounded
              : Icons.view_stream_rounded,
          size: 16,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
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
    );
  }

  // =====================================================================
  //  食材分类区块
  // =====================================================================
  Widget _buildIngredientSection(
      BuildContext context, String type, List<String> items, bool isDark) {
    final icon = _typeIcons[type] ?? Icons.category_rounded;
    final color = _typeColors[type] ?? AppTheme.primaryColor;
    final selectedInType =
        items.where((i) => _selectedIngredients.contains(i)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 类型头部 ----
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 8),
              if (selectedInType > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$selectedInType/${items.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                )
              else
                Text(
                  '${items.length}',
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

          // ---- 食材 chips ----
          if (_compactIngredients)
            _buildCompactGrid(items, isDark, color)
          else
            _buildWrapChips(items, isDark, color),
        ],
      ),
    );
  }

  // 紧凑网格
  Widget _buildCompactGrid(List<String> items, bool isDark, Color typeColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            (constraints.maxWidth / 110).floor().clamp(2, 6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 3.4,
          ),
          itemBuilder: (context, idx) {
            final ingredient = items[idx];
            final isSelected = _selectedIngredients.contains(ingredient);
            return _IngredientChip(
              label: ingredient,
              isSelected: isSelected,
              isDark: isDark,
              typeColor: typeColor,
              compact: true,
              onTap: () => _toggleIngredient(ingredient),
              key: _ingredientKeys[ingredient],
            );
          },
        );
      },
    );
  }

  // 常规 Wrap
  Widget _buildWrapChips(List<String> items, bool isDark, Color typeColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((ingredient) {
        final isSelected = _selectedIngredients.contains(ingredient);
        return _IngredientChip(
          label: ingredient,
          isSelected: isSelected,
          isDark: isDark,
          typeColor: typeColor,
          compact: false,
          onTap: () => _toggleIngredient(ingredient),
          key: _ingredientKeys[ingredient],
        );
      }).toList(),
    );
  }

  // =====================================================================
  //  推荐菜品面板 — 玻璃态
  // =====================================================================
  Widget _buildRecipesPanel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen
                      .withValues(alpha: isDark ? 0.08 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ---- 面板头部 ----
                _buildRecipesHeader(isDark),

                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppTheme.accentGreen.withValues(alpha: 0.1),
                ),

                // ---- 菜品列表 ----
                Expanded(
                  child: _matchedRecipes.isEmpty
                      ? _buildEmptyRecipesState(isDark)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                              index,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipesHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            t('RecommendedRecipes'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: _matchedRecipes.isNotEmpty
                  ? AppTheme.greenGradient
                  : null,
              color: _matchedRecipes.isEmpty
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_matchedRecipes.length} ${_selectedLanguage == 'zh' ? '道' : 'found'}',
              style: TextStyle(
                color: _matchedRecipes.isNotEmpty
                    ? Colors.white
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecipesState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.primaryColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedIngredients.isEmpty
                  ? Icons.touch_app_rounded
                  : Icons.search_off_rounded,
              size: 34,
              color: isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),
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
          if (_selectedIngredients.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _selectedLanguage == 'zh' ? '点击上方食材开始' : 'Tap ingredients above to start',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark.withValues(alpha: 0.6)
                    : AppTheme.textSecondaryLight.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================================
  //  菜谱卡片 — 带入场动画 + 色彩匹配度
  // =====================================================================
  Widget _buildRecipeCard(
    BuildContext context,
    String recipeName,
    List<String> requiredIngredients,
    String matchPercentage,
    bool isDark,
    int index,
  ) {
    final matchPercent = double.tryParse(matchPercentage) ?? 0;
    final matchColor = matchPercent >= 80
        ? AppTheme.accentGreen
        : matchPercent >= 50
            ? AppTheme.accentOrange
            : AppTheme.primaryColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index % 6) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!mounted) return;
              final food = _foodMap[recipeName];
              if (food != null) {
                Navigator.push(
                  context,
                  _SlideFadeRoute(page: RecipeDetailPage(recipeInfo: food)),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          matchColor.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          matchColor.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: matchColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 左侧彩色竖条
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: matchColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recipeName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        // 匹配度胶囊 — 渐变
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                matchColor,
                                matchColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: matchColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pie_chart_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$matchPercentage%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          requiredIngredients.take(6).map((ingredient) {
                        final isSelected =
                            _selectedIngredients.contains(ingredient);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? matchColor.withValues(alpha: 0.18)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black
                                        .withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: matchColor.withValues(alpha: 0.3),
                                    width: 0.8)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(Icons.check_circle_rounded,
                                      size: 11, color: matchColor),
                                ),
                              Text(
                                ingredient,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? matchColor
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
                        '+${requiredIngredients.length - 6} ${_selectedLanguage == 'zh' ? '更多食材' : 'more'}',
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
        ),
      ),
    );
  }
}

// =========================================================================
//  食材芯片组件（带按压缩放动画）
// =========================================================================
class _IngredientChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color typeColor;
  final bool compact;
  final VoidCallback onTap;

  const _IngredientChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.typeColor,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_IngredientChip> createState() => _IngredientChipState();
}

class _IngredientChipState extends State<_IngredientChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;
    final color = widget.typeColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.15)),
              width: isSelected ? 1.2 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize:
                widget.compact ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_rounded,
                      size: widget.compact ? 11 : 13, color: Colors.white),
                ),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
