import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/providers/auth_provider.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class RecipeDetailPage extends StatefulWidget {
  final Food recipeInfo;

  const RecipeDetailPage({
    super.key,
    required this.recipeInfo,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with TickerProviderStateMixin {
  String _selectedLanguage = 'zh';
  bool _isFavorited = false;
  bool _oriFavorited = false;
  bool _hasSavedOnExit = false;

  // ---- 动画 ----
  late AnimationController _entryController;
  late AnimationController _fabController;
  late Animation<double> _heroFade;
  late Animation<double> _infoSlide;
  late Animation<double> _infoFade;
  late Animation<double> _fabScale;

  // Hero 区域渐变色（根据菜名 hash 选择）
  late List<Color> _heroColors;

  static const List<List<Color>> _gradientPalette = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFFee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    [Color(0xFF2D6CDF), Color(0xFF5A8FE8)],
    [Color(0xFFFF9500), Color(0xFFFFB84D)],
  ];

  static const List<IconData> _heroIcons = [
    Icons.restaurant_rounded,
    Icons.ramen_dining_rounded,
    Icons.lunch_dining_rounded,
    Icons.local_pizza_rounded,
    Icons.soup_kitchen_rounded,
    Icons.set_meal_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipeInfo.steps.isEmpty) {
      _loadRecipeBecauseOfItIsEmpty();
    }
    _initLanguageFromPrefs();
    _initFavoriteState();
    _initColors();
    _initAnimations();
  }

  void _initColors() {
    final idx = widget.recipeInfo.name.hashCode.abs() % _gradientPalette.length;
    _heroColors = _gradientPalette[idx];
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    ));

    _infoSlide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));
    _infoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    _entryController.forward();

    // FAB 弹入
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScale = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  Future<void> _loadRecipeBecauseOfItIsEmpty() async {
    await FoodDatabaseHelper.instance
        .getFoodById(widget.recipeInfo.id.toString())
        .then((food) {
      if (food != null) {
        setState(() {
          widget.recipeInfo.ingredients = food.ingredients;
          widget.recipeInfo.steps = food.steps;
          widget.recipeInfo.nutritionTags = food.nutritionTags;
        });
      }
    });
  }

  Future<void> _initFavoriteState() async {
    final liked = await isFoodFavorited(widget.recipeInfo.id.toString());
    if (!mounted) return;
    setState(() {
      _isFavorited = liked;
      _oriFavorited = liked;
    });
  }

  String t(String key) => Translations.translate(key, _selectedLanguage);

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() => _selectedLanguage = saved);
    appLanguageNotifier.value = saved;
  }

  Future<void> changeLove(bool nowFavorited) async {
    if (nowFavorited == _oriFavorited) return;
    try {
      await FoodDatabaseHelper.instance
          .changeLove(widget.recipeInfo, nowFavorited);
      if (mounted) setState(() => _isFavorited = nowFavorited);
    } catch (e) {
      debugPrint('Error changing favorite: $e');
    }
  }

  Future<bool> isFoodFavorited(String id) async {
    return await FoodDatabaseHelper.instance.isFoodFavorited(id);
  }

  @override
  void dispose() {
    if (!_hasSavedOnExit) {
      changeLove(_isFavorited);
      _hasSavedOnExit = true;
    }
    _entryController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ---- 顶部 Hero 区域 (SliverAppBar) ----
                    _buildSliverAppBar(isDark),

                    // ---- 内容区域 ----
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: Offset(0, _infoSlide.value),
                        child: Opacity(
                          opacity: _infoFade.value,
                          child: _buildContentBody(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // ---- 收藏 FAB ----
          floatingActionButton: AnimatedBuilder(
            animation: _fabScale,
            builder: (ctx, child) => Transform.scale(
              scale: _fabScale.value,
              child: child,
            ),
            child: _buildFab(context, isLoggedIn, isDark),
          ),
        );
      },
    );
  }

  // =====================================================================
  //  SliverAppBar — 渐变 Hero + 装饰
  // =====================================================================
  SliverAppBar _buildSliverAppBar(bool isDark) {
    final iconIdx =
        widget.recipeInfo.name.hashCode.abs() % _heroIcons.length;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: _heroColors[0],
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Opacity(
          opacity: _heroFade.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _heroColors,
              ),
            ),
            child: Stack(
              children: [
                // 装饰圆
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: 20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // 中心图标
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          _heroIcons[iconIdx],
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.recipeInfo.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      if (widget.recipeInfo.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.recipeInfo.description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 底部渐变过渡
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark
                                  ? const Color(0xFF16213E)
                                  : const Color(0xFFE8F0FE))
                              .withValues(alpha: 0.6),
                        ],
                      ),
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

  // =====================================================================
  //  主内容区
  // =====================================================================
  Widget _buildContentBody(bool isDark) {
    final hasTags = widget.recipeInfo.nutritionTags.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 快捷信息卡片行 ----
          _buildQuickInfoRow(isDark),
          if (hasTags) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              isDark: isDark,
              icon: Icons.local_offer_rounded,
              iconColor: AppTheme.accentOrange,
              gradient: AppTheme.orangeGradient,
              title: _selectedLanguage == 'zh'
                  ? '营养标签 (${widget.recipeInfo.nutritionTags.length})'
                  : 'Nutrition Tags (${widget.recipeInfo.nutritionTags.length})',
              child: _buildNutritionTagsList(isDark),
            ),
          ],
          const SizedBox(height: 24),

          // ---- 食材区 ----
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.eco_rounded,
            iconColor: AppTheme.accentGreen,
            gradient: AppTheme.greenGradient,
            title: _selectedLanguage == 'zh'
                ? '食材 (${widget.recipeInfo.ingredients.length})'
                : 'Ingredients (${widget.recipeInfo.ingredients.length})',
            child: _buildIngredientsList(isDark),
          ),
          const SizedBox(height: 16),

          // ---- 步骤区 ----
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.menu_book_rounded,
            iconColor: AppTheme.primaryColor,
            gradient: AppTheme.primaryGradient,
            title: _selectedLanguage == 'zh'
                ? '做法 (${widget.recipeInfo.steps.length}步)'
                : 'Steps (${widget.recipeInfo.steps.length})',
            child: _buildStepsList(isDark),
          ),
        ],
      ),
    );
  }

  // ---- 快捷信息行 ----
  Widget _buildQuickInfoRow(bool isDark) {
    return Row(
      children: [
        _buildInfoChip(
          isDark,
          Icons.eco_rounded,
          '${widget.recipeInfo.ingredients.length}',
          _selectedLanguage == 'zh' ? '种食材' : 'Ingredients',
          AppTheme.accentGreen,
        ),
        const SizedBox(width: 10),
        _buildInfoChip(
          isDark,
          Icons.format_list_numbered_rounded,
          '${widget.recipeInfo.steps.length}',
          _selectedLanguage == 'zh' ? '个步骤' : 'Steps',
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 10),
        _buildInfoChip(
          isDark,
          Icons.timer_rounded,
          '${(widget.recipeInfo.steps.length * 5).clamp(10, 60)}',
          _selectedLanguage == 'zh' ? '分钟' : 'Min',
          AppTheme.accentOrange,
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      bool isDark, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- 通用区块卡片 ----
  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required LinearGradient gradient,
    required String title,
    required Widget child,
  }) {
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
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.1 : 0.06),
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
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
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
              ),
              // 分隔
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : iconColor.withValues(alpha: 0.08),
              ),
              // 内容
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 食材列表 ----
  Widget _buildNutritionTagsList(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.recipeInfo.nutritionTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentOrange.withValues(
                alpha: isDark ? 0.28 : 0.2,
              ),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_rounded,
                size: 14,
                color: AppTheme.accentOrange,
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIngredientsList(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.recipeInfo.ingredients.map((ingredient) {
        final colorIdx =
            ingredient.hashCode.abs() % _gradientPalette.length;
        final chipColor = _gradientPalette[colorIdx][0];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withValues(alpha: isDark ? 0.25 : 0.2),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: chipColor),
              const SizedBox(width: 6),
              Text(
                ingredient,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---- 步骤列表 ----
  Widget _buildStepsList(bool isDark) {
    return Column(
      children: widget.recipeInfo.steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;
        final isLast = idx == widget.recipeInfo.steps.length - 1;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + idx * 80),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间轴
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _heroColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _heroColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _heroColors[0].withValues(alpha: 0.4),
                              _heroColors[0].withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // 步骤内容
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : _heroColors[0].withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : _heroColors[0].withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =====================================================================
  //  收藏 FAB — 带动画
  // =====================================================================
  Widget _buildFab(BuildContext context, bool isLoggedIn, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('PleaseLoginFirst')),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        setState(() => _isFavorited = !_isFavorited);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: _isFavorited
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFee5a24)],
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.06),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.5),
                            ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFavorited
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppTheme.accentRed.withValues(alpha: 0.2)),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFavorited
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(_isFavorited),
                    color: _isFavorited
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.accentRed),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t('favoriteAdd'),
                  style: TextStyle(
                    color: _isFavorited
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
