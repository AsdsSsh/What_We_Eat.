import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/search_detail_page.dart';

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

  // 移除：本页不再做即时搜索列表展示
  // List<String> _searchResults = [];
  // bool _isSearching = false;


  final Map<String, String> _recipeDetails = {
    '番茄鸡蛋': '简单易做，适合快手早餐',
    '宫保鸡丁': '经典川菜，酸辣开胃',
    '红烧肉': '家常菜，肥而不腻',
    '酸辣汤': '暖胃汤品，营养丰富',
    '清蒸鱼': '清淡健康，保留鱼鲜',
    '土豆咖喱': '异域风味，简单易做',
    '麻辣火锅': '团聚必选，味道丰富',
    '蛋炒饭': '快手主食，简单美味',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 移除：_performSearch / _clearHistory 在详细页处理

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：输入框（点击进入详细搜索页，无搜索按钮）
            Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
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
                child: TextField(
                  controller: _searchController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: '搜索菜谱',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            // 中间主体：可拖动 + 下拉刷新 + 分页加载
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFoods,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _visibleFoods.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_hasMore && index == _visibleFoods.length) {
                      // 底部加载指示
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
                          ),
                        ),
                      );
                    }
                    final recipe = _visibleFoods[index];
                    return _buildRecipeCard(recipe.name);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 保留：卡片点击进入详情
  Widget _buildRecipeCard(String recipe) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipeName: recipe),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 32,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                recipe,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _recipeDetails[recipe] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}