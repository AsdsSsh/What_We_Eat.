import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/recipe_detail_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class RandomRecipePage extends StatefulWidget {
  const RandomRecipePage({super.key});

  @override
  State<RandomRecipePage> createState() => _RandomRecipePageState();
}

class _RandomRecipePageState extends State<RandomRecipePage>
    with TickerProviderStateMixin {
  int _recipeCount = 3;
  double _budget = 50;
  List<Food> _randomRecipes = [];
  bool _hasGenerated = false;
  bool _isLoading = false;

  // 从数据库加载的真实食物数据
  List<Food> _allFoods = [];

  // 页面统一主色：暖粉金
  static const Color _accent = Color(0xFFfa709a);
  static const Color _accentEnd = Color(0xFFFee140);
  static const List<Color> _accentGradient = [_accent, _accentEnd];

  String get _lang => appLanguageNotifier.value;
  String t(String key) => Translations.translate(key, _lang);

  // ---- 动画 ----
  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;
  late Animation<double> _settingsFade;
  late Animation<double> _settingsSlide;
  late Animation<double> _btnFade;
  late Animation<double> _btnSlide;

  // 结果区域单独动画
  AnimationController? _resultController;
  Animation<double>? _resultFade;
  Animation<double>? _resultSlide;

  // 骰子旋转动画
  late AnimationController _diceController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadFoodsFromDatabase();
  }

  /// 从数据库加载真实食物数据
  Future<void> _loadFoodsFromDatabase() async {
    final foods = await FoodDatabaseHelper.instance.getAllFoods();
    if (mounted) {
      setState(() {
        _allFoods = foods;
      });
    }
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    ));
    _headerSlide = Tween<double>(begin: -20, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.35, curve: Curves.easeOutCubic),
    ));

    _settingsFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    ));
    _settingsSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    ));

    _btnFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    ));
    _btnSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    ));

    _entryController.forward();

    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _triggerResultAnimation() {
    _resultController?.dispose();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _resultController!,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    ));
    _resultSlide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(
      parent: _resultController!,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    ));
    _resultController!.forward();
  }

  void _generateRandomRecipes() {
    if (_allFoods.isEmpty) return;

    _diceController.forward(from: 0);

    final random = Random();
    final filteredFoods =
        _allFoods.where((f) => f.budget <= _budget).toList();

    if (filteredFoods.isEmpty) {
      setState(() {
        _randomRecipes = [];
        _hasGenerated = true;
      });
      _triggerResultAnimation();
      return;
    }

    filteredFoods.shuffle(random);
    setState(() {
      _randomRecipes = filteredFoods.take(_recipeCount).toList();
      _hasGenerated = true;
    });
    _triggerResultAnimation();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _resultController?.dispose();
    _diceController.dispose();
    super.dispose();
  }

  // ==================================================================
  //  BUILD
  // ==================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          body: AnimatedBuilder(
            animation: _entryController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A1A2E),
                            Color(0xFF16213E),
                            Color(0xFF0F3460),
                          ],
                          stops: [0.0, 0.3, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF0F4FF),
                            Color(0xFFE8F0FE),
                            Color(0xFFFFF8F0),
                          ],
                          stops: [0.0, 0.3, 1.0],
                        ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- 顶栏 ----
                        Transform.translate(
                          offset: Offset(0, _headerSlide.value),
                          child: Opacity(
                            opacity: _headerFade.value,
                            child: _buildHeader(isDark),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ---- 设置面板 ----
                        Transform.translate(
                          offset: Offset(0, _settingsSlide.value),
                          child: Opacity(
                            opacity: _settingsFade.value,
                            child: _buildSettingsPanel(isDark),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ---- 生成按钮 ----
                        Transform.translate(
                          offset: Offset(0, _btnSlide.value),
                          child: Opacity(
                            opacity: _btnFade.value,
                            child: _buildGenerateButton(isDark),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---- 结果区域 ----
                        if (_hasGenerated) _buildResultsSection(isDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================================================================
  //  顶栏
  // ==================================================================
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 22,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // 骰子图标
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFfa709a), Color(0xFFFee140)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFfa709a).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _diceController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _diceController.value * 2 * pi,
                child: child,
              );
            },
            child: const Icon(Icons.casino_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _lang == 'zh' ? '随机菜谱' : 'Random Recipes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _lang == 'zh' ? '让灵感决定今天吃什么' : 'Let inspiration decide',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================================
  //  设置面板 — 玻璃态
  // ==================================================================
  Widget _buildSettingsPanel(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部彩色装饰条
              Container(
                width: double.infinity,
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFFee140)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFfa709a), Color(0xFFFee140)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _lang == 'zh' ? '随机设置' : 'Random Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ---- 菜谱数量 ----
                    _buildSliderSection(
                      isDark: isDark,
                      icon: Icons.restaurant_menu_rounded,
                      label: _lang == 'zh' ? '菜谱数量' : 'Recipe Count',
                      valueText: '$_recipeCount',
                      unit: _lang == 'zh' ? '道' : '',
                      slider: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _accent,
                          inactiveTrackColor: _accent.withValues(alpha: isDark ? 0.15 : 0.12),
                          thumbColor: Colors.white,
                          overlayColor: _accent.withValues(alpha: 0.15),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _recipeCount.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          onChanged: (v) =>
                              setState(() => _recipeCount = v.toInt()),
                        ),
                      ),
                      tickLabels: ['1', '2', '3', '4', '5'],
                    ),

                    const SizedBox(height: 20),

                    // ---- 预算上限 ----
                    _buildSliderSection(
                      isDark: isDark,
                      icon: Icons.savings_rounded,
                      label: _lang == 'zh' ? '预算上限' : 'Budget Limit',
                      valueText: '¥${_budget.toInt()}',
                      unit: '',
                      slider: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _accent,
                          inactiveTrackColor: _accent.withValues(alpha: isDark ? 0.15 : 0.12),
                          thumbColor: Colors.white,
                          overlayColor: _accent.withValues(alpha: 0.15),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _budget,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          onChanged: (v) => setState(() => _budget = v),
                        ),
                      ),
                      tickLabels: ['¥10', '', '', '', '¥200'],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required bool isDark,
    required IconData icon,
    required String label,
    required String valueText,
    required String unit,
    required Widget slider,
    required List<String> tickLabels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _accentGradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const Spacer(),
            // 数值胶囊
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _accentGradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$valueText $unit'.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        slider,
        // 刻度标签
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tickLabels
                .map((l) => Text(
                      l,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ==================================================================
  //  生成按钮 — 渐变 + 缩放
  // ==================================================================
  Widget _buildGenerateButton(bool isDark) {
    return _TapScaleButton(
      onTap: _generateRandomRecipes,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFfa709a), Color(0xFFFee140)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFfa709a).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _diceController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _diceController.value * 2 * pi,
                  child: child,
                );
              },
              child: const Icon(Icons.casino_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 10),
            Text(
              _lang == 'zh' ? '开始随机' : 'Generate Random',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  //  结果区域
  // ==================================================================
  Widget _buildResultsSection(bool isDark) {
    if (_resultController == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _resultController!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _resultSlide?.value ?? 0),
          child: Opacity(
            opacity: _resultFade?.value ?? 0,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                _lang == 'zh' ? '随机结果' : 'Random Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              if (_randomRecipes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_randomRecipes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (_randomRecipes.isEmpty)
            _buildEmptyState(isDark)
          else
            ...List.generate(_randomRecipes.length, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration:
                    Duration(milliseconds: 400 + index * 100),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: _buildRecipeResultCard(
                    isDark, _randomRecipes[index], index),
              );
            }),

          // 总价汇总
          if (_randomRecipes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTotalRow(isDark),
          ],
        ],
      ),
    );
  }

  // ---- 单张结果卡片 ----
  Widget _buildRecipeResultCard(
      bool isDark, Food food, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipeInfo: food),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : _accent.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: isDark ? 0.08 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 统一主色渐变图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _accentGradient),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: _accent.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 价格胶囊
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '¥${food.budget.toInt()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- 总价行 ----
  Widget _buildTotalRow(bool isDark) {
    final total =
        _randomRecipes.fold<double>(0, (sum, f) => sum + f.budget);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.5),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.accentGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 18,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                  const SizedBox(width: 8),
                  Text(
                    _lang == 'zh' ? '预估总价' : 'Estimated Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '¥${total.toInt()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 空状态 ----
  Widget _buildEmptyState(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.accentOrange.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sentiment_dissatisfied_rounded,
                    size: 32, color: AppTheme.accentOrange),
              ),
              const SizedBox(height: 14),
              Text(
                _lang == 'zh'
                    ? '没有符合预算的菜谱'
                    : 'No recipes within budget',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _lang == 'zh' ? '请尝试提高预算上限' : 'Please increase budget limit',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  通用缩放按钮
// =====================================================================
class _TapScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapScaleButton({required this.onTap, required this.child});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
