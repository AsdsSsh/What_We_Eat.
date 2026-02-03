import 'package:flutter/material.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/favorite_food.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/recipe_detail_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class MyfavoritePage extends StatefulWidget {
  const MyfavoritePage({super.key});

  @override
  State<MyfavoritePage> createState() => _MyfavoritePageState();
}

class _MyfavoritePageState extends State<MyfavoritePage> {
  List<FavoriteFood> favoriteFoods = [];
  bool _isLoading = false;

  Future<void> _loadFavoriteFoods() async {
    setState(() => _isLoading = true);
    final result = await FoodDatabaseHelper.instance.getFavoriteFoods();
    if (!mounted) return;
    setState(() {
      favoriteFoods = result;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String id) async {
    await FoodDatabaseHelper.instance.removeFavoriteFood(id);
    await _loadFavoriteFoods();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消收藏')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteFoods();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : favoriteFoods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppTheme.greenGradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '收藏夹空空如也',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '浏览菜谱时点击收藏按钮\n将喜欢的菜谱保存到这里',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.explore_rounded),
                          label: const Text('去探索菜谱'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteFoods.length,
                  itemBuilder: (context, index) {
                    final fav = favoriteFoods[index];
                    return _buildFavoriteCard(fav, isDark);
                  },
                ),
    );
  }

  Widget _buildFavoriteCard(FavoriteFood fav, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () {
          // 构造 Food 对象并跳转详情
          final food = Food(
            id: fav.id,
            name: fav.name,
            description: fav.description,
            ingredients: [],
            steps: [],
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailPage(recipeInfo: food),
            ),
          ).then((_) => _loadFavoriteFoods());
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fav.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fav.description.isNotEmpty ? fav.description : '美味佳肴',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade400,
                onPressed: () => _removeFavorite(fav.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}