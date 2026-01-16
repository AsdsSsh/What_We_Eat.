import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  @override
  void initState() {
    super.initState();
    _getFood();
  }

  List<Food> _foodList = [];
  void _getFood() async {
    final foods = await FoodDatabaseHelper.instance.getAllFoods();
    setState(()  {
      _foodList = foods;
    });
  }
  
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = ['番茄鸡蛋', '宫保鸡丁', '红烧肉', '酸辣汤'];
  List<String> _searchResults = [];
  bool _isSearching = false;

  final List<String> _popularRecipes = [
    '番茄鸡蛋',
    '宫保鸡丁',
    '红烧肉',
    '酸辣汤',
    '清蒸鱼',
    '土豆咖喱',
    '麻辣火锅',
    '蛋炒饭',
  ];

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
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    // Add to search history if not already there
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    // Perform search (simple keyword matching)
    final results = _popularRecipes
        .where((recipe) => recipe.contains(query))
        .toList();

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清空搜索历史'),
          content: const Text('确定要清空所有搜索历史吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchHistory.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: '搜索菜谱',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
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
            // Content
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildDefaultView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hot Recipes Section
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _foodList.length,
            itemBuilder: (context, index) {
              final recipe = _foodList[index];
              return _buildRecipeCard(recipe.name);
            },
          ),
          const SizedBox(height: 24),

          // Search History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('搜索历史'),
              _searchHistory.isNotEmpty
                  ? GestureDetector(
                      onTap: _clearHistory,
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
          const SizedBox(height: 12),
          _searchHistory.isEmpty
              ? Center(
                  child: Text(
                    '暂无搜索历史',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _searchHistory.map((query) {
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = query;
                        _performSearch(query);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          query,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
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

  Widget _buildSearchResults() {
    return _searchResults.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '未找到相关菜谱',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final recipe = _searchResults[index];
              return _buildRecipeListItem(recipe);
            },
          );
  }

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

  Widget _buildRecipeListItem(String recipe) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.restaurant_menu, color: Colors.blue.shade700),
        title: Text(recipe),
        subtitle: Text(_recipeDetails[recipe] ?? ''),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipeName: recipe),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[900],
      ),
    );
  }
}