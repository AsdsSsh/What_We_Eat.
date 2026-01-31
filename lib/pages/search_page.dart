import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/search_detail_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  // 分页与刷新相关状态
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 8;
  
  // 移除 _allFoods，改为按需加载
  List<Food> _visibleFoods = [];
  int _currentOffset = 0;
  int _totalCount = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  // 新增：刷新锁和防抖
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initLoad();
    _scrollController.addListener(_onScrollLoadMore);
  }

  // 初始化加载：获取总数并加载第一页
  Future<void> _initLoad() async {
    final count = await FoodDatabaseHelper.instance.getFoodsCount();
    final firstPage = await FoodDatabaseHelper.instance.getFoodsPaginated(_pageSize, 0);
    setState(() {
      _totalCount = count;
      _visibleFoods = firstPage;
      _currentOffset = firstPage.length;
      _hasMore = _currentOffset < _totalCount;
      _isLoadingMore = false;
    });
  }

  // 滚动监听，接近底部时加载下一页
  void _onScrollLoadMore() {
    if (_isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  // 加载更多：从数据库取下一页
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = await FoodDatabaseHelper.instance.getFoodsPaginated(_pageSize, _currentOffset);
    setState(() {
      _visibleFoods.addAll(nextPage);
      _currentOffset += nextPage.length;
      _hasMore = _currentOffset < _totalCount;
      _isLoadingMore = false;
    });
  }

  // 下拉刷新：添加锁和防抖
  Future<void> _refreshFoods() async {
    // 防止重复刷新
    if (_isRefreshing) return;
    
    // 防抖：限制刷新频率
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
      
      // 添加超时处理
      await _initLoad().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('刷新超时，请重试')),
            );
          }
        },
      );
    } finally {
      _isRefreshing = false;
    }
  }

  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = ['番茄鸡蛋', '宫保鸡丁', '红烧肉', '酸辣汤'];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部搜索区域
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '搜索菜谱',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchDetailPage(
                            initialQuery: '',
                            initialHistory: _searchHistory,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '搜索你想要的菜谱...',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 热门菜谱标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 $_totalCount 道',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 中间主体：可拖动 + 下拉刷新 + 分页加载
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFoods,
                color: AppTheme.primaryColor,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _visibleFoods.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_hasMore && index == _visibleFoods.length) {
                      // 底部加载指示
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }
                    final recipe = _visibleFoods[index];
                    return _buildRecipeCard(context, recipe, isDark);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Food recipe, bool isDark) {
    // 根据菜名生成渐变色
    final colorIndex = recipe.name.hashCode % 4;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
    ];
    final colors = gradients[colorIndex];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipeInfo: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图标区域
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        recipe.description.isNotEmpty ? recipe.description : '美味佳肴',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: AppTheme.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} 种食材',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
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
    );
  }
}