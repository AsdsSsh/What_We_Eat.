import 'package:flutter/material.dart';


class RecipeDetailPage extends StatefulWidget {
  final String recipeName;

  const RecipeDetailPage({
    super.key,
    required this.recipeName,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}


class _RecipeDetailPageState extends State<RecipeDetailPage> {
  // Recipe database with detailed information
  final Map<String, Map<String, dynamic>> _recipeDatabase = {
    '番茄鸡蛋': {
      'description': '简单易做，适合快手早餐',
      'ingredients': ['番茄 2个', '鸡蛋 3个', '油 适量', '盐 适量'],
      'steps': [
        '1. 番茄切块，鸡蛋打入碗中搅拌',
        '2. 热锅下油，炒香番茄块',
        '3. 加入鸡蛋液，快速翻炒',
        '4. 加盐调味，出锅前滴几滴醋',
      ],
    },
    '宫保鸡丁': {
      'description': '经典川菜，酸辣开胃',
      'ingredients': ['鸡肉 300g', '花生 100g', '辣椒 2个', '酱油 3勺', '糖 1勺'],
      'steps': [
        '1. 鸡肉切丁，用酱油腌制15分钟',
        '2. 花生炒香，辣椒切段',
        '3. 热锅下油，炒鸡肉至变色',
        '4. 加入花生、辣椒，翻炒均匀',
        '5. 加糖调味，淋上酱油',
      ],
    },
    '红烧肉': {
      'description': '家常菜，肥而不腻',
      'ingredients': ['猪肉 500g', '酱油 4勺', '糖 2勺', '生姜 3片', '大蒜 3瓣'],
      'steps': [
        '1. 猪肉切块，焯水去血沫',
        '2. 热锅下油，炒糖至焦香',
        '3. 放入猪肉块翻炒至上色',
        '4. 加生姜、大蒜、酱油和清水',
        '5. 炖煮30分钟至肉软',
        '6. 大火收汁即可',
      ],
    },
    '清蒸鱼': {
      'description': '清淡健康，保留鱼鲜',
      'ingredients': ['鱼 1条', '生姜 3片', '葱 2根', '酱油 2勺', '油 1勺'],
      'steps': [
        '1. 鱼洗净，放入蒸盘，撒盐',
        '2. 铺上生姜片和葱段',
        '3. 水烧开，放入蒸15分钟',
        '4. 取出后淋上酱油和热油',
      ],
    },
    '酸辣汤': {
      'description': '暖胃汤品，营养丰富',
      'ingredients': ['豆腐 200g', '醋 3勺', '辣椒 2个', '盐 适量', '生姜 2片'],
      'steps': [
        '1. 豆腐切块，各食材准备好',
        '2. 热汤锅，加入豆腐块',
        '3. 加入辣椒、生姜烧开',
        '4. 倒入醋，调整口味',
        '5. 煮2分钟后出锅',
      ],
    },
    '土豆咖喱': {
      'description': '异域风味，简单易做',
      'ingredients': ['土豆 2个', '洋葱 1个', '油 2勺', '盐 适量', '咖喱粉 2勺'],
      'steps': [
        '1. 土豆、洋葱切块',
        '2. 热锅下油，炒洋葱至香',
        '3. 加入土豆块翻炒',
        '4. 加入咖喱粉和清水',
        '5. 煮20分钟至土豆软',
      ],
    },
    '蛋炒饭': {
      'description': '快手主食，简单美味',
      'ingredients': ['米 2碗', '鸡蛋 2个', '油 2勺', '盐 适量', '葱 1根'],
      'steps': [
        '1. 鸡蛋打散，米饭准备好',
        '2. 热锅下油，炒鸡蛋至半熟',
        '3. 加入米饭快速翻炒',
        '4. 加盐调味',
        '5. 最后加葱段出锅',
      ],
    },
  };

  // Sample nearby restaurants
  final List<Map<String, String>> _nearbyRestaurants = [
    {
      'name': '老北京饭庄',
      'distance': '0.8 km',
      'rating': '4.5',
      'reviews': '2340',
      'address': '中关村大街88号',
    },
    {
      'name': '家常菜馆',
      'distance': '1.2 km',
      'rating': '4.3',
      'reviews': '1860',
      'address': '长安街105号',
    },
    {
      'name': '味道十足',
      'distance': '1.5 km',
      'rating': '4.6',
      'reviews': '3210',
      'address': '海淀区西三环52号',
    },
    {
      'name': '美食城',
      'distance': '1.8 km',
      'rating': '4.2',
      'reviews': '1650',
      'address': '朝阳区建国路15号',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final recipe = _recipeDatabase[widget.recipeName] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeName),
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
                    widget.recipeName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['description'] ?? '',
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
                    '食材 (${recipe['ingredients']?.length ?? 0})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(recipe['ingredients'] as List<String>?)?.map((ingredient) {
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
                      }).toList() ??
                      [],
                  const SizedBox(height: 24),

                  // Steps section
                  Text(
                    '做法 (${recipe['steps']?.length ?? 0}步)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(recipe['steps'] as List<String>?)?.asMap().entries.map((entry) {
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
                      }).toList() ??
                      [],
                  const SizedBox(height: 24),

                  // Nutrition info - REMOVED
                  // Tips - REMOVED

                  const SizedBox(height: 32),

                  // Nearby restaurants section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '附近餐厅',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '更多',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._nearbyRestaurants.map((restaurant) {
                    return _buildRestaurantCard(restaurant);
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已收藏此菜谱！')),
          );
        },
        label: const Text('收藏菜谱'),
        icon: const Icon(Icons.favorite_border),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, String> restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant['address'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          restaurant['rating'] ?? '0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant['reviews']}条评价',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '距离：${restaurant['distance']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('即将导航到${restaurant['name']}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation, size: 14),
                  label: const Text('导航'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
