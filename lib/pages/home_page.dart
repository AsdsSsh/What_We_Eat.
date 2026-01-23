import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/my_favorite_page.dart';
import 'package:what_we_eat/pages/recommend_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onExplore;

  const HomePage({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '吃了么',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '帮你决策今天吃什么，提供菜谱、随机推荐与搜索功能。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 个性化推荐
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RecommendPage()),
                          );
                        },
                        splashColor: Colors.green.withValues(alpha: 0.2),
                        child: ListTile(
                          leading: Icon(Icons.lightbulb, color: Colors.orange),
                          title: Text('个性化推荐',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('查看我们为你提供的个性化推荐!'),
                        ),
                      ),
                      const Divider(),
                      // 食材烹饪 - 通过底部导航栏跳转
                      InkWell(
                        onTap: () {
                          if (onExplore != null) {
                            onExplore!();
                          }
                        },
                        splashColor: Colors.green.withValues(alpha: 0.2),
                        child: ListTile(
                          leading: Icon(Icons.restaurant_menu, color: Colors.blue),
                          title: Text('食材烹饪',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('根据你所拥有的食材给出合理的菜谱!'),
                        ),
                      ),
                      const Divider(),
                      // 美食收藏
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyfavoritePage()),
                          );
                        },
                        splashColor: Colors.green.withValues(alpha: 0.2),
                        child: ListTile(
                          leading: Icon(Icons.restaurant, color: Colors.green),
                          title: Text('美食收藏',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('你所收藏的菜谱。'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
