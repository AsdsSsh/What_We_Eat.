import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/search_detail_page.dart';
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  // 分页与刷新相关状态
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 8;

  List<Food> _visibleFoods = [];
  int _currentOffset = 0;
  int _totalCount = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _selectedLanguage = 'zh';

  // 刷新锁和防抖
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2);

  // 入场动画
  late AnimationController _entryController;
  late Animation<double> _searchBarSlide;
  late Animation<double> _searchBarFade;
  late Animation<double> _counterFade;
  late Animation<double> _gridFade;

  @override
  void initState() {
    super.initState();
    _initLoad();
    _initLanguageFromPrefs();
    _scrollController.addListener(_onScrollLoadMore);
    _initAnimations();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _searchBarSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    ));
    _searchBarFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    ));

    _counterFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    ));

    _gridFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    ));

    _entryController.forward();
  }

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }

  Future<void> _initLoad() async {
    final count = await FoodDatabaseHelper.instance.getFoodsCount();
    final firstPage =
        await FoodDatabaseHelper.instance.getFoodsPaginated(_pageSize, 0);
    setState(() {
      _totalCount = count;
      _visibleFoods = firstPage;
      _currentOffset = firstPage.length;
      _hasMore = _currentOffset < _totalCount;
      _isLoadingMore = false;
    });
  }

  void _onScrollLoadMore() {
    if (_isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = await FoodDatabaseHelper.instance
        .getFoodsPaginated(_pageSize, _currentOffset);
    setState(() {
      _visibleFoods.addAll(nextPage);
      _currentOffset += nextPage.length;
      _hasMore = _currentOffset < _totalCount;
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshFoods() async {
    if (_isRefreshing) return;
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      return;
    }

    _isRefreshing = true;
    _lastRefreshTime = now;

    try {
      setState(() {
        _visibleFoods = [];
        _currentOffset = 0;
        _hasMore = true;
      });

      await _initLoad().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    _selectedLanguage == 'zh' ? '刷新超时，请重试' : 'Refresh timed out'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      );
    } finally {
      _isRefreshing = false;
    }
  }

  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = ['番茄鸡蛋', '宫保鸡丁', '红烧肉', '酸辣汤'];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A1A2E),
                          Color(0xFF16213E),
                          Color(0xFF0F3460),
                        ],
                        stops: [0.0, 0.4, 1.0],
                      )
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF0F4FF),
                          Color(0xFFE8F0FE),
                          Color(0xFFFFF8F0),
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
              ),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) {
                  return SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- 搜索栏 ----
                        Transform.translate(
                          offset: Offset(0, _searchBarSlide.value),
                          child: Opacity(
                            opacity: _searchBarFade.value,
                            child: _buildSearchBar(context, isDark),
                          ),
                        ),

                        // ---- 计数标签 ----
                        Opacity(
                          opacity: _counterFade.value,
                          child: _buildCounterRow(isDark),
                        ),
                        const SizedBox(height: 8),

                        // ---- 网格列表 ----
                        Expanded(
                          child: Opacity(
                            opacity: _gridFade.value,
                            child: RefreshIndicator(
                              onRefresh: _refreshFoods,
                              color: AppTheme.primaryColor,
                              backgroundColor:
                                  isDark ? AppTheme.surfaceDark : Colors.white,
                              child: GridView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: _visibleFoods.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_hasMore &&
                                      index == _visibleFoods.length) {
                                    return _buildLoadingIndicator(isDark);
                                  }
                                  final recipe = _visibleFoods[index];
                                  return _SearchRecipeCard(
                                    recipe: recipe,
                                    isDark: isDark,
                                    index: index,
                                    language: _selectedLanguage,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        });
  }

  // =====================================================================
  //  搜索栏 — 玻璃态
  // =====================================================================
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            _SlideFadeRoute(
              page: SearchDetailPage(
                initialQuery: '',
                initialHistory: _searchHistory,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppTheme.primaryColor.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor
                        .withValues(alpha: isDark ? 0.1 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t('InputKeywords'),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedLanguage == 'zh' ? '搜索' : 'Search',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // =====================================================================
  //  计数行
  // =====================================================================
  Widget _buildCounterRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _selectedLanguage == 'zh'
                ? '发现 $_totalCount 道菜谱'
                : 'Discover $_totalCount recipes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 14, color: AppTheme.accentOrange),
                const SizedBox(width: 4),
                Text(
                  _selectedLanguage == 'zh' ? '热门' : 'Hot',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  //  加载指示器
  // =====================================================================
  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
//  单个菜谱卡片（带入场动画 + 点击缩放）
// =========================================================================
class _SearchRecipeCard extends StatefulWidget {
  final Food recipe;
  final bool isDark;
  final int index;
  final String language;

  const _SearchRecipeCard({
    required this.recipe,
    required this.isDark,
    required this.index,
    required this.language,
  });

  @override
  State<_SearchRecipeCard> createState() => _SearchRecipeCardState();
}

class _SearchRecipeCardState extends State<_SearchRecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  // 预定义渐变色组
  static const List<List<Color>> _gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFFee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ];

  // 食物图标
  static const List<IconData> _foodIcons = [
    Icons.restaurant_menu_rounded,
    Icons.ramen_dining_rounded,
    Icons.lunch_dining_rounded,
    Icons.local_pizza_rounded,
    Icons.icecream_rounded,
    Icons.soup_kitchen_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.94).animate(
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
    final recipe = widget.recipe;
    final isDark = widget.isDark;
    final colorIndex = recipe.name.hashCode.abs() % _gradients.length;
    final colors = _gradients[colorIndex];
    final iconIndex = recipe.name.hashCode.abs() % _foodIcons.length;

    // 入场动画：交错延迟
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index % 8) * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _ctrl.forward();
        },
        onTapUp: (_) {
          _ctrl.reverse();
          Navigator.push(
            context,
            _SlideFadeRoute(page: RecipeDetailPage(recipeInfo: recipe)),
          );
        },
        onTapCancel: () {
          _ctrl.reverse();
        },
        child: AnimatedBuilder(
          animation: _scale,
          builder: (ctx, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? colors[0].withValues(alpha: 0.25)
                        : colors[0].withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          colors[0].withValues(alpha: isDark ? 0.15 : 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- 顶部渐变区 + 图标 ----
                    Container(
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Stack(
                        children: [
                          // 装饰圆
                          Positioned(
                            right: -16,
                            top: -16,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -10,
                            bottom: -10,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          // 图标
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _foodIcons[iconIndex],
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---- 内容区域 ----
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                recipe.description.isNotEmpty
                                    ? recipe.description
                                    : (widget.language == 'zh'
                                        ? '美味佳肴'
                                        : 'Delicious dish'),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors[0].withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.eco_rounded,
                                        size: 12,
                                        color: colors[0],
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${recipe.ingredients.length} ${widget.language == 'zh' ? '食材' : 'items'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
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
        ),
      ),
    );
  }
}