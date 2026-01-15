import 'package:flutter/material.dart';
import 'recipe_detail_page.dart';


class DoDishPage extends StatefulWidget {
  const DoDishPage({super.key});

  @override
  State<DoDishPage> createState() => _DoDishPageState();
}


class _DoDishPageState extends State<DoDishPage>
    with TickerProviderStateMixin {
  // Available ingredients
  final List<String> _allIngredients = [
    '鸡蛋', '番茄', '米', '油', '盐',
    '鸡肉', '猪肉', '牛肉', '鱼', '虾',
    '青菜', '豆腐', '土豆', '洋葱', '大蒜',
    '生姜', '葱', '辣椒', '酱油', '醋',
    '糖', '花生', '芝麻', '面粉', '黄瓜',
  ];

  // Ingredient to icon mapping
  final Map<String, IconData> _ingredientIcons = {
    '鸡蛋': Icons.egg,
    '番茄': Icons.nature,
    '米': Icons.grain,
    '油': Icons.opacity,
    '盐': Icons.blur_on,
    '鸡肉': Icons.dinner_dining,
    '猪肉': Icons.pets,
    '牛肉': Icons.lunch_dining,
    '鱼': Icons.pets,
    '虾': Icons.bug_report,
    '青菜': Icons.spa,
    '豆腐': Icons.blender,
    '土豆': Icons.storage,
    '洋葱': Icons.circle,
    '大蒜': Icons.bubble_chart,
    '生姜': Icons.local_florist,
    '葱': Icons.grass,
    '辣椒': Icons.local_fire_department,
    '酱油': Icons.format_color_fill,
    '醋': Icons.water_drop,
    '糖': Icons.cake,
    '花生': Icons.circle,
    '芝麻': Icons.brightness_1,
    '面粉': Icons.cloud,
    '黄瓜': Icons.check_circle,
  };

  // Ingredient to color mapping
  final Map<String, Color> _ingredientColors = {
    '鸡蛋': Colors.yellow,
    '番茄': Colors.red,
    '米': Colors.amber,
    '油': Colors.yellow,
    '盐': Colors.grey,
    '鸡肉': Colors.orange,
    '猪肉': Colors.pink,
    '牛肉': Colors.red,
    '鱼': Colors.blue,
    '虾': Colors.orange,
    '青菜': Colors.green,
    '豆腐': Colors.white70,
    '土豆': Colors.brown,
    '洋葱': Colors.purple,
    '大蒜': Colors.grey,
    '生姜': Colors.orange,
    '葱': Colors.green,
    '辣椒': Colors.red,
    '酱油': Colors.brown,
    '醋': Colors.amber,
    '糖': Colors.orange,
    '花生': Colors.brown,
    '芝麻': Colors.grey,
    '面粉': Colors.amber,
    '黄瓜': Colors.green,
  };

  // Recipes with required ingredients
  final Map<String, List<String>> _recipes = {
    '番茄鸡蛋': ['番茄', '鸡蛋', '油', '盐'],
    '宫保鸡丁': ['鸡肉', '花生', '辣椒', '酱油', '糖'],
    '红烧肉': ['猪肉', '酱油', '糖', '生姜', '大蒜'],
    '清蒸鱼': ['鱼', '生姜', '葱', '酱油'],
    '酸辣汤': ['豆腐', '醋', '辣椒', '盐', '生姜'],
    '土豆咖喱': ['土豆', '洋葱', '油', '盐'],
    '炒青菜': ['青菜', '油', '盐', '大蒜'],
    '蛋炒饭': ['米', '鸡蛋', '油', '盐', '葱'],
    '虾仁炒饭': ['虾', '米', '鸡蛋', '油', '盐'],
    '豆腐炒': ['豆腐', '油', '盐', '大蒜', '葱'],
  };

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
    for (var ingredient in _allIngredients) {
      _ingredientKeys[ingredient] = GlobalKey();
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleIngredient(String ingredient) {
    // Immediately update selection state
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
      _updateMatchedRecipes();
      // Then set ingredient to animate
      _animatingIngredient = ingredient;
    });
    
    // Play animation after state update
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _animatingIngredient = null;
        });
      }
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
        // Return center of the text
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

    _matchedRecipes = _recipes.entries
        .where((entry) {
          // Check if all recipe ingredients are in selected ingredients
          return entry.value.every((ingredient) => _selectedIngredients.contains(ingredient));
        })
        .map((entry) => entry.key)
        .toList();
  }

  void _clearSelection() {
    setState(() {
      _selectedIngredients.clear();
      _matchedRecipes = [];
    });
  }

  void _randomMatch() {
    if (_allIngredients.isEmpty) return;
    
    // Randomly select 3-5 ingredients
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
      appBar: AppBar(
        title: const Text('一键做菜'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basket indicator at top
                Center(
                  child: Container(
                    key: _basketKey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          key: _basketTextKey,
                          '已选食材: ${_selectedIngredients.length}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '选择你有的食材',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '我们会为你推荐适合的菜谱',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
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
            const SizedBox(height: 20),

            // Ingredients Section
            Text(
              '选择食材 (${_selectedIngredients.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allIngredients.map((ingredient) {
                final icon = _ingredientIcons[ingredient] ?? Icons.circle;
                final color = _ingredientColors[ingredient] ?? Colors.grey;
                
                return GestureDetector(
                  onTap: () => _toggleIngredient(ingredient),
                  child: Container(
                    key: _ingredientKeys[ingredient],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedIngredients.contains(ingredient)
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedIngredients.contains(ingredient)
                            ? color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: _selectedIngredients.contains(ingredient)
                              ? color
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedIngredients.contains(ingredient)
                                ? color
                                : Colors.grey[700],
                            fontWeight: _selectedIngredients.contains(ingredient)
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Matched Recipes Section
            Text(
              '推荐菜谱 (${_matchedRecipes.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            _matchedRecipes.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _matchedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _matchedRecipes[index];
                      final requiredIngredients = _recipes[recipe] ?? [];
                      final matchPercentage =
                          ((requiredIngredients.length / requiredIngredients.length) * 100)
                              .toStringAsFixed(0);
                      
                      return _buildRecipeCard(
                        context,
                        recipe,
                        requiredIngredients,
                        matchPercentage,
                      );
                    },
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
          // Flying animation layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                if (_animatingIngredient == null || _animationController.value == 0) {
                  return const SizedBox.shrink();
                }
                
                // Use easeInOutCubic for smooth motion
                const curve = Curves.easeInOutCubic;
                final animValue = curve.transform(_animationController.value);
                final ingredient = _animatingIngredient!;
                final icon = _ingredientIcons[ingredient] ?? Icons.circle;
                final color = _ingredientColors[ingredient] ?? Colors.grey;
                
                // Get start and end positions
                final startPos = _getIngredientPosition();
                final endPos = _getBasketPosition();
                
                // Interpolate position
                final currentX = startPos.dx + (endPos.dx - startPos.dx) * animValue;
                final currentY = startPos.dy + (endPos.dy - startPos.dy) * animValue;
                
                // Change icon and opacity
                const transitionPoint = 0.65; // When to switch to bowl icon
                final isShowingBowl = animValue > transitionPoint;
                final showBowlOpacity = isShowingBowl
                    ? ((animValue - transitionPoint) / (1.0 - transitionPoint)).clamp(0.0, 1.0)
                    : 0.0;
                
                // Scale animation
                final scale = 1.0 - (animValue * 0.4);
                
                return Positioned(
                  left: currentX - 20,
                  top: currentY - 20,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Original ingredient icon (fades out)
                          Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: (1.0 - animValue * 0.3).clamp(0.0, 1.0),
                              child: Icon(
                                icon,
                                color: color,
                                size: 24,
                              ),
                            ),
                          ),
                          // Bowl icon (fades in)
                          Transform.scale(
                            scale: scale * 0.9,
                            child: Opacity(
                              opacity: showBowlOpacity,
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                      '100% 匹配',
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
                  final icon = _ingredientIcons[ingredient] ?? Icons.circle;
                  final color = _ingredientColors[ingredient] ?? Colors.grey;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? color : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? color : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
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