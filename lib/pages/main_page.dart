import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/components/bottom_nav_bar.dart';
import 'package:what_we_eat/config/app_config.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/do_dish_page.dart';
import 'package:what_we_eat/pages/home_page.dart';
import 'package:what_we_eat/pages/me_page.dart';
import 'package:what_we_eat/pages/search_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/providers/auth_provider.dart';
import 'package:what_we_eat/theme/app_theme.dart';


class MainPage extends StatefulWidget {
  

  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> with WidgetsBindingObserver {

  int _selectedIndex = 0;
  String _selectedLanguage = 'zh';

  late final List<Widget> _pages;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      HomePage(onExplore: () => _onItemTapped(1)),
      const DoDishPage(),
      const SearchPage(),
    ];
  }
  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }

  void _onItemTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = index;
    });
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台恢复时刷新登录状态
    if (state == AppLifecycleState.resumed) {
      Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        return Scaffold(
          drawer: _buildDrawer(context, isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppTheme.surfaceDark 
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: isDark 
                        ? AppTheme.textPrimaryDark 
                        : AppTheme.textPrimaryLight,
                    size: 20,
                  ),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          extendBodyBehindAppBar: true,
          bottomNavigationBar: BottomNavBar(
            onTabChange: (index) => _onItemTapped(index),
            selectedIndex: _selectedIndex,
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _pages,
          ),
        );
      }
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      child: Column(
        children: [
          // Custom Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  title: t('home'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(0);
                  },
                  isSelected: _selectedIndex == 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: t('setting'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_rounded,
                  title: t('me'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MePage()),
                    );
                  },
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppConfig.versionText,
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
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected 
            ? AppTheme.primaryColor.withValues(alpha: 0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}