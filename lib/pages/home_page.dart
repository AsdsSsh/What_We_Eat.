import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/do_dish_page.dart';


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
                    Icon(
                      Icons.restaurant_menu,
                      size: 84,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '今天吃什么？',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lightbulb, color: Colors.orange),
                        title: Text('智能推荐', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('根据偏好与食材推荐菜谱。'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.restaurant, color: Colors.green),
                        title: Text('美食收藏', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('把喜欢的菜谱保存起来。'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.search, color: Colors.blue),
                        title: Text('快速搜索', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('查找附近最近的美食餐厅。'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 47, 106, 209)),
                  onPressed: onExplore ?? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoDishPage()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Text('开始探索', style: TextStyle(fontSize: 16 , color: Colors.black)),
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