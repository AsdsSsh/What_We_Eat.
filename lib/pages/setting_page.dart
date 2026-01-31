import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/config/app_config.dart';
import 'package:what_we_eat/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Section
            _buildSectionTitle('通知设置', isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: '推送通知',
                  subtitle: '接收菜谱推荐和应用更新',
                  value: _notificationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  icon: Icons.schedule_rounded,
                  iconColor: AppTheme.accentOrange,
                  title: '每日推荐',
                  subtitle: '每天上午 12:00 推送菜谱建议',
                  enabled: _notificationEnabled,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('推送时间已设置为 12:00')),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Display Section
            _buildSectionTitle('显示设置', isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: isDark ? Colors.amber : Colors.indigo,
                  title: '深色模式',
                  subtitle: '保护眼睛的暗色主题',
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
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Info Section
            _buildSectionTitle('应用信息', isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildInfoTile(
                  icon: Icons.info_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: '应用版本',
                  value: AppConfig.fullVersion,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  icon: Icons.storage_rounded,
                  iconColor: Colors.grey,
                  title: '缓存大小',
                  subtitle: '约 2.5 MB',
                  onTap: () => _showClearCacheDialog(),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  icon: Icons.language_rounded,
                  iconColor: Colors.purple,
                  title: '语言',
                  subtitle: '简体中文',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('语言设置已保存')),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Maintenance Section
            _buildSectionTitle('维护', isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildNavigationTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppTheme.accentRed,
                  title: '清空所有数据',
                  subtitle: '删除本地保存的所有数据（不可恢复）',
                  onTap: () => _showClearAllDataDialog(),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2024 吃了么',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? iconColor : iconColor.withValues(alpha: 0.3),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled
              ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)
              : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: enabled
            ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
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