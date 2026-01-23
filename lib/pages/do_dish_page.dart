import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';

class DoDishPage extends StatefulWidget {
  const DoDishPage({super.key});

  @override
  State<DoDishPage> createState() => _DoDishPageState();
}

class _DoDishPageState extends State<DoDishPage>
    with TickerProviderStateMixin {
  // Available ingredients (改为动态，从数据库读取)
  List<String> _allIngredients = [];
  // 按类型分组的原材料
  Map<String, List<String>> _ingredientsByType = {};
  // Recipes with required ingredients（改为动态加载）
  Map<String, List<String>> _recipes = {};
  Set<String> _selectedIngredients = {};
  List<String> _matchedRecipes = [];
  late AnimationController _animationController;
  String? _animatingIngredient;
  final Map<String, GlobalKey> _ingredientKeys = {};
  late GlobalKey _basketKey;
  late GlobalKey _basketTextKey;

  @override
  void initState() {
    super.initState();
    _basketKey = GlobalKey();
    _basketTextKey = GlobalKey();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadIngredientsFromDb();
    _loadRecipesFromDb();
  }

  Future<void> _loadIngredientsFromDb() async {
    try {
      final rows = await FoodDatabaseHelper.instance.getAllRawMaterials();
      print('DEBUG: 加载的原材料行数: ${rows.length}');
      print('DEBUG: 原材料原始数据: $rows');
      final names = rows
          .map((r) => (r['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      print('DEBUG: 提取的原材料名称: $names');
      final Map<String, List<String>> grouped = {};
      for (final r in rows) {
        final name = (r['name'] as String?) ?? '';
        if (name.isEmpty) continue;
        final type = (r['type'] as String?) ?? '其他';
        grouped.putIfAbsent(type, () => []).add(name);
      }
      print('DEBUG: 分组后的原材料: $grouped');
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
      print('ERROR: 堆栈追踪: ${StackTrace.current}');
    }
  }

  // 新增：从数据库 foods 表读取菜谱及其所需原材料
  Future<void> _loadRecipesFromDb() async {
    try {
      final List<Food> foods = await FoodDatabaseHelper.instance.getAllFoods();
      print('DEBUG: 加载的菜谱数量: ${foods.length}');
      final Map<String, List<String>> map = {
        for (final f in foods) f.name: List<String>.from(f.ingredients)
      };
      setState(() {
        _recipes = map;
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

  Offset _getIngredientPosition() {
    final ingredient = _animatingIngredient;
    if (ingredient == null) return Offset.zero;
    try {
      final renderBox = _ingredientKeys[ingredient]
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        return renderBox.localToGlobal(Offset.zero);
      }
    } catch (e) {
      //
    }
    return Offset.zero;
  }

  Offset _getBasketPosition() {
    try {
      final renderBox =
          _basketTextKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        return position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
      }
    } catch (e) {
      //
    }
    return Offset.zero;
  }

  void _updateMatchedRecipes() {
    if (_selectedIngredients.isEmpty) {
      _matchedRecipes = [];
      return;
    }
    // 修改逻辑：用户选择的食材是菜品所需食材的子集即可匹配
    _matchedRecipes = _recipes.entries
        .where((entry) {
          final requiredSet = Set<String>.from(entry.value);
          // 用户选择的每一个食材都在菜品所需中
          return _selectedIngredients.every((ingredient) => requiredSet.contains(ingredient));
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
      _matchedRecipes = [];
    });
  }

  void _randomMatch() {
    if (_allIngredients.isEmpty) return;
    final random = List<String>.from(_allIngredients)..shuffle();
    final count = 3 + (random.length % 3);
    setState(() {
      _selectedIngredients = Set.from(random.take(count));
      _updateMatchedRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 顶部固定区域：按钮 + "选择食材"标题
              Container(
                color: Colors.grey[300],
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 按钮行
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shuffle),
                            label: const Text('随机匹配'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _randomMatch,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('清空'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _clearSelection,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // "选择食材"标题
                    Text(
                      '选择食材 (${_selectedIngredients.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),

              // 上半部分：食材选择区域（可滚动）
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_ingredientsByType.isEmpty)
                        const Text('原材料加载中或为空', style: TextStyle(color: Colors.grey))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _ingredientsByType.entries.map((entry) {
                            final type = entry.key;
                            final items = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: items.map((ingredient) {
                                      return GestureDetector(
                                        onTap: () => _toggleIngredient(ingredient),
                                        child: Container(
                                          key: _ingredientKeys[ingredient],
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _selectedIngredients.contains(ingredient)
                                                ? Colors.blue.withValues(alpha: 0.2)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _selectedIngredients.contains(ingredient)
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            ingredient,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _selectedIngredients.contains(ingredient)
                                                  ? Colors.blue
                                                  : Colors.grey[700],
                                              fontWeight: _selectedIngredients.contains(ingredient)
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // 分隔线
              Divider(height: 1, color: Colors.grey[300]),

              // 下半部分：推荐菜品区域（可滚动）
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '推荐菜谱 (${_matchedRecipes.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _matchedRecipes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedIngredients.isEmpty
                                        ? '选择食材以查看推荐菜谱'
                                        : '没有找到匹配的菜谱',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _matchedRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _matchedRecipes[index];
                                final requiredIngredients = _recipes[recipe] ?? [];
                                final matchPercentage =
                                    _calcMatchPercent(requiredIngredients).toStringAsFixed(0);
                                return _buildRecipeCard(
                                  context,
                                  recipe,
                                  requiredIngredients,
                                  matchPercentage,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 固定在顶部的按钮区域
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: const Text('随机匹配'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _randomMatch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('清空'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _clearSelection,
                    ),
                  ),
                ],
              ),
            ),
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
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('即将查看 $recipeName 的详细步骤')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    recipeName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$matchPercentage% 匹配',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '需要食材：',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requiredIngredients.map((ingredient) {
                  final isSelected = _selectedIngredients.contains(ingredient);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('查看做法'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailPage(recipeName: recipeName),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}