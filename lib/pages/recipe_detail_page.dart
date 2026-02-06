import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/providers/auth_provider.dart';


class RecipeDetailPage extends StatefulWidget {
  final Food recipeInfo;

  const RecipeDetailPage({
    super.key,
    required this.recipeInfo,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}


class _RecipeDetailPageState extends State<RecipeDetailPage> {
  String _selectedLanguage = 'zh';
  bool _isFavorited = false;
  bool _oriFavorited = false;
  bool _hasSavedOnExit = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipeInfo.steps.isEmpty) {
      _loadRecipeBecauseOfItIsEmpty();
    }
    _initLanguageFromPrefs();
    _initFavoriteState();
  }


  Future<void> _loadRecipeBecauseOfItIsEmpty() async {
    await FoodDatabaseHelper.instance.getFoodById(widget.recipeInfo.id.toString()).then((food) {
      if (food != null) {
        setState(() {
          widget.recipeInfo.ingredients = food.ingredients;
          widget.recipeInfo.steps = food.steps;
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


  // 检查并更改收藏状态
  Future<void> changeLove(bool nowFavorited) async {
    if (nowFavorited == _oriFavorited) return;
    try {
      await FoodDatabaseHelper.instance.changeLove(widget.recipeInfo , nowFavorited);
      if (mounted) setState(() => _isFavorited = true);
    } catch (e) {
      print('Error adding favorite food: $e');
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
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.recipeInfo.name),
            backgroundColor: const Color.fromARGB(255, 47, 106, 209),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image section
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade300,
                        Colors.blue.shade600,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 100,
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
        
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info
                      Text(
                        widget.recipeInfo.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.recipeInfo.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
        
                      // Quick info cards - REMOVED
                      
                      const SizedBox(height: 24),
        
                      // Ingredients section
                      Text(
                        '食材 (${widget.recipeInfo.ingredients.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.recipeInfo.ingredients.map((ingredient) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    ingredient,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      const SizedBox(height: 24),
        
                      // Steps section
                      Text(
                        '做法 (${widget.recipeInfo.steps.length}步)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.recipeInfo.steps.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (!isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('PleaseLoginFirst'))),
                );
                return;
              }
              // 改变状态以改变图标
              setState(() {
                _isFavorited = !_isFavorited;
              });
            },
            label: Text(t('favoriteAdd')),
            icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    );
  }


}
