import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/config/app_config.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/theme/app_theme.dart';

// 主题通知器
final ValueNotifier<ThemeMode> appThemeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);
// 语言通知器
final ValueNotifier<String> appLanguageNotifier =
    ValueNotifier<String>('zh');


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}


class _SettingPageState extends State<SettingPage> {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'zh';

  @override
  void initState() {
    super.initState();
    _initThemeFromPrefs();
    _initLanguageFromPrefs();
    _initNotificationFromPrefs();
  }

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  Future<void> _initNotificationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('notificationEnabled') ?? true;
    setState(() {
      _notificationEnabled = saved;
    });
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

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t('setting')),
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
            _buildSectionTitle(t('notificationSetting'), isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: t('pushNotification'),
                  subtitle: t('receiveNotification'),
                  value: _notificationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Display Section
            _buildSectionTitle(t('displaySetting'), isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: isDark ? Colors.amber : Colors.indigo,
                  title: t('darkMode'),
                  subtitle: t('protectEyes'),
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
            _buildSectionTitle(t('appInfo'), isDark),
            _buildSettingsCard(
              isDark,
              children: [
                _buildInfoTile(
                  icon: Icons.info_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: t('version'),
                  value: AppConfig.fullVersion,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  icon: Icons.storage_rounded,
                  iconColor: Colors.grey,
                  title: t('cacheSize'),
                  subtitle: '约 2.5 MB',
                  onTap: () => _showClearCacheDialog(),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  icon: Icons.language_rounded,
                  iconColor: Colors.purple,
                  title: t('language'),
                  subtitle: _selectedLanguage == 'zh' ? '简体中文' : 'English',
                  onTap: () => showLanguageDialog(),
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
                AppConfig.trademark,
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
          title: Text(t('clearCache')),
          content: Text(t('confirmClearCache')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(t('confirm')),
            ),
          ],
        );
      },
    );
  }

  void showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(t('selectLanguage')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      child: RadioGroup<String>(
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            _selectedLanguage = value;
                          });
                          final message = value == 'zh' 
                              ? '语言已切换为简体中文' 
                              : 'Language switched to English';
                          _changeLanguage(value, message);
                        },
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  _selectedLanguage = 'zh';
                                });
                                _changeLanguage('zh', '语言已切换为简体中文');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: 'zh',
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('简体中文'),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  _selectedLanguage = 'en';
                                });
                                _changeLanguage('en', 'Language switched to English');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: 'en',
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('English'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeLanguage(String? value, String message) async {
    if (value == null) return;
    
    setState(() {
      _selectedLanguage = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', value);
    
    appLanguageNotifier.value = value;

    if (mounted) {
      Navigator.pop(context);
    }
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
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有数据已清空')),
                );
              },
              child: Text(
                t('confirmDelete'),
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        );
      },
    );
  }
}