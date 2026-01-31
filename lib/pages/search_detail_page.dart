import 'package:flutter/material.dart';
import 'package:what_we_eat/database/food_database_helper.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/recipe_detail_page.dart';

class SearchDetailPage extends StatefulWidget {
  final String initialQuery;
  final List<String> initialHistory;

  const SearchDetailPage({
    super.key,
    required this.initialQuery,
    required this.initialHistory,
  });

  @override
  State<SearchDetailPage> createState() => _SearchDetailPageState();
}

class _SearchDetailPageState extends State<SearchDetailPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  List<String> _searchHistory = [];
  List<Food> _allFoods = [];
  List<Food> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _queryCtrl.text = widget.initialQuery;
    _searchHistory = List<String>.from(widget.initialHistory);
    _loadFoods().then((_) {
      if (_queryCtrl.text.trim().isNotEmpty) {
        _performSearch();
      }
    });
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    final foods = await FoodDatabaseHelper.instance.getAllFoods();
    setState(() {
      _allFoods = foods;
      _loading = false;
    });
  }

  void _performSearch() {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    // 写入历史
    if (!_searchHistory.contains(q)) {
      setState(() {
        _searchHistory.insert(0, q);
        if (_searchHistory.length > 20) _searchHistory.removeLast();
      });
    }
    // 关键词匹配（菜谱名）
    final matched = _allFoods.where((f) => f.name.contains(q)).toList();
    setState(() => _results = matched);
  }

  void _clearHistory() {
    setState(() => _searchHistory.clear());
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('详细搜索'),
        backgroundColor: const Color.fromARGB(255, 47, 106, 209),
      ),
      body: Column(
        children: [
          // 顶部：输入框 + 搜索按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: InputDecoration(
                      hintText: '输入菜谱关键词',
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
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('搜索'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _performSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // 历史
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '搜索历史',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    if (_searchHistory.isNotEmpty)
                      GestureDetector(
                        onTap: _clearHistory,
                        child: Text(
                          '清空',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _searchHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('暂无历史', style: TextStyle(color: Colors.grey[500])),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _searchHistory.map((q) {
                          return GestureDetector(
                            onTap: () {
                              _queryCtrl.text = q;
                              _performSearch();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(q, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),
                // 结果
                Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Colors.blue.shade700),
                    ),
                  )
                else if (_results.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('未找到相关菜谱', style: TextStyle(color: Colors.grey[600])),
                    ),
                  )
                else
                  ..._results.map((f) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.restaurant_menu, color: Colors.blue.shade700),
                        title: Text(f.name),
                        subtitle: Text(f.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeInfo: f)),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
