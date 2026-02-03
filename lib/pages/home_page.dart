import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/my_favorite_page.dart';
import 'package:what_we_eat/pages/recommend_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onExplore;

  const HomePage({super.key, this.onExplore});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedLanguage = 'zh';

   @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
  }


  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }
  // TODO 继续完成国际化
  // TODO 完成设置页面的实际逻辑
  // TODO 我的收藏完成

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder监听语言和主题变化
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  Center(
                    child: Column(
                      children: [
                        // Logo with gradient background
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t('appName'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
        
                  // Quick Actions Section
                  Text(
                    t("QuickStart"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
        
                  // Feature Cards
                  _buildFeatureCard(
                    context,
                    icon: Icons.lightbulb_rounded,
                    title: t('PersonalizedRecommendations'),
                    subtitle: t('PersonalizedRecommendationsSubtitle'),
                    gradient: AppTheme.orangeGradient,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecommendPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.restaurant_menu_rounded,
                    title: t('IngredientCooking'),
                    subtitle: t('SelectIngredientsSubtitle'),
                    gradient: AppTheme.primaryGradient,
                    onTap: () {
                      if (widget.onExplore != null) {
                        widget.onExplore!();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.favorite_rounded,
                    title: t('MyFavorites'),
                    subtitle: t('MyFavoritesSubtitle'),
                    gradient: AppTheme.greenGradient,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyfavoritePage()),
                      );
                    },
                  ),
        
                  const SizedBox(height: 32),
        
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, '30+', t('Recipe')),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                        _buildStatItem(context, '∞', t('Possibilities')),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                        _buildStatItem(context, '50+', t('Ingredients')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
