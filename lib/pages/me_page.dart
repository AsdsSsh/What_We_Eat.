import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/config/app_config.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/edit_profile_page.dart';
import 'package:what_we_eat/pages/login_page.dart';
import 'package:what_we_eat/pages/my_favorite_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/pages/about_us_page.dart';
import 'package:what_we_eat/pages/feedback_page.dart';
import 'package:what_we_eat/providers/auth_provider.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  String _selectedLanguage = 'zh';

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
    // 每次进入页面时刷新登录状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
    });
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
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        return Scaffold(
          appBar: AppBar(
            title: Text(t('me')),
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
                  color:
                      isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
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
                // User Profile Card
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    children: [
                      // 顶部模糊背景
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade200,
                              Colors.orange.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: isLoggedIn
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const EditProfilePage(),
                                        ),
                                      );
                                      if (result == true) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // 头像和用户信息
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Column(
                          children: [
                            // 头像
                            GestureDetector(
                              onTap: isLoggedIn
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const EditProfilePage(),
                                        ),
                                      );
                                      if (result == true) {
                                        setState(() {});
                                      }
                                    }
                                  : null,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.surfaceDark
                                      : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 用户名
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLoggedIn ? (auth.userName ?? t('User')) : t('Unlogged'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                                ),
                                if (isLoggedIn) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 用户ID 或 登录按钮
                            if (isLoggedIn)
                              Text(
                                '@${auth.email ?? 'unknown'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.login_rounded,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        t('login/register'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            // 统计信息（仅登录后显示）
                            if (isLoggedIn)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatItem('', t('MyFavoritesCnt'), isDark, onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const MyfavoritePage()),
                                    );
                                  }),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
        
                // Menu Section
                _buildSectionTitle(t('FunctionMenu'), isDark),
                const SizedBox(height: 12),
        
                _buildMenuCard(
                  context,
                  isDark,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_rounded,
                      iconColor: AppTheme.primaryColor,
                      title: t('setting'),
                      subtitle: t('AppPreferences'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingPage()),
                      ),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_rounded,
                      iconColor: AppTheme.accentGreen,
                      title: t('AboutUs'),
                      subtitle: t('ViewAppinformation'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutUsPage()),
                      ),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuItem(
                      context,
                      icon: Icons.feedback_rounded,
                      iconColor: AppTheme.accentOrange,
                      title: t('Feedback'),
                      subtitle: t('SendFeedback'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FeedbackPage()),
                      ),
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
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color:
            isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, bool isDark,
      {required List<Widget> children}) {
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
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
          color:
              isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
