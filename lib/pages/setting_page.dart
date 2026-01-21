import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}


class _SettingPageState extends State<SettingPage> {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  bool _saveFavorites = true;
  String _servingSize = '2人份';

  ThemeData get _currentTheme => _darkModeEnabled
      ? ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.grey[900],
          cardColor: Colors.grey[850],
        )
      : ThemeData.light();

  @override
  void initState() {
    super.initState();
    _initThemeFromPrefs();
  }

  Future<void> _initThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('darkModeEnabled') ?? false;
    setState(() {
      _darkModeEnabled = saved;
    });
    appThemeModeNotifier.value =
        saved ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _currentTheme,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
          backgroundColor: const Color.fromARGB(255, 47, 106, 209),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Section
              _buildSectionTitle('通知设置'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.notifications, color: Colors.blue.shade700),
                      title: const Text('推送通知'),
                      subtitle: const Text('接收菜谱推荐和应用更新'),
                      trailing: Switch(
                        value: _notificationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationEnabled = value;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.alarm, color: Colors.orange.shade700),
                      title: const Text('每日推荐'),
                      subtitle: const Text('每天上午 12:00 推送菜谱建议'),
                      enabled: _notificationEnabled,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: _notificationEnabled ? Colors.grey[400] : Colors.grey[300],
                      ),
                      onTap: _notificationEnabled
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('推送时间已设置为 12:00')),
                            );
                          }
                        : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Display Section
              _buildSectionTitle('显示设置'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.dark_mode, color: Colors.grey.shade700),
                  title: const Text('深色模式'),
                  subtitle: const Text('保护眼睛的暗色主题'),
                  trailing: Switch(
                    value: _darkModeEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      appThemeModeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('darkModeEnabled', value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Food Preferences Section
              _buildSectionTitle('食物偏好'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.people, color: Colors.green.shade700),
                      title: const Text('默认份量'),
                      subtitle: Text(_servingSize),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      onTap: () => _showServingSizeDialog(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.bookmark, color: Colors.red.shade700),
                      title: const Text('保存收藏'),
                      subtitle: const Text('自动保存你喜欢的菜谱'),
                      trailing: Switch(
                        value: _saveFavorites,
                        onChanged: (value) {
                          setState(() {
                            _saveFavorites = value;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.local_fire_department, color: Colors.orange.shade700),
                      title: const Text('饮食限制'),
                      subtitle: const Text('设置不食用的食材'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('正在加载饮食限制...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Info Section
              _buildSectionTitle('应用信息'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info, color: Colors.blue),
                      title: Text('应用版本'),
                      subtitle: Text('v0.0.3'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.storage, color: Colors.grey.shade700),
                      title: const Text('缓存大小'),
                      subtitle: const Text('约 2.5 MB'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      onTap: () {
                        _showClearCacheDialog();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.language, color: Colors.purple.shade700),
                      title: const Text('语言'),
                      subtitle: const Text('简体中文'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('语言设置已保存')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Maintenance Section
              _buildSectionTitle('维护'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  title: const Text('清空所有数据'),
                  subtitle: const Text('删除本地保存的所有数据（不可恢复）'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  onTap: () {
                    _showClearAllDataDialog();
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  '© 2024 今天吃什么？',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[900],
        ),
      ),
    );
  }

  void _showServingSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择默认份量'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['1人份', '2人份', '3人份', '4人份'].map((String value) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _servingSize = value;
                    });
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Radio<String>(
                        value: value,
                        // ignore: deprecated_member_use
                        groupValue: _servingSize,
                        // ignore: deprecated_member_use
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _servingSize = newValue;
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(value),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清空缓存'),
          content: const Text('确定要清空应用缓存吗？这将释放存储空间。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清空')),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清空所有数据'),
          content: const Text(
            '确定要删除所有本地数据吗？\n\n此操作将：\n• 删除所有收藏的菜谱\n• 删除所有设置\n• 删除所有浏览历史\n\n此操作无法恢复！',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有数据已清空')),
                );
              },
              child: Text(
                '确定删除',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        );
      },
    );
  }
}