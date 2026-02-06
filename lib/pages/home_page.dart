import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/ai_assistant_page.dart';
import 'package:what_we_eat/pages/random_recipe_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onExplore;

  const HomePage({super.key, this.onExplore});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedLanguage = 'zh';
  late String _currentReason;
  late String _recommendedDish;

  final List<Map<String, String>> _recommendations = [
    {
      'reason_zh': '现在是早晨，来一份营养均衡的早餐吧',
      'reason_en': 'It\'s morning, time for a balanced breakfast',
      'dish_zh': '番茄鸡蛋面',
      'dish_en': 'Tomato Egg Noodles',
    },
    {
      'reason_zh': '您今天已经吃了较多肉类，推荐一道清淡的蔬菜',
      'reason_en': 'You\'ve had a lot of meat today, try some vegetables',
      'dish_zh': '清炒时蔬',
      'dish_en': 'Stir-fried Vegetables',
    },
    {
      'reason_zh': '现在是晚餐时间，来点容易消化的食物',
      'reason_en': 'It\'s dinner time, try something easy to digest',
      'dish_zh': '小米粥配凉拌黄瓜',
      'dish_en': 'Millet Porridge with Cucumber Salad',
    },
    {
      'reason_zh': '根据营养学建议，您需要补充更多蛋白质',
      'reason_en': 'Based on nutrition advice, you need more protein',
      'dish_zh': '红烧排骨',
      'dish_en': 'Braised Pork Ribs',
    },
    {
      'reason_zh': '天气有点冷，来碗热腾腾的汤暖暖身子',
      'reason_en': 'It\'s cold outside, warm up with a hot soup',
      'dish_zh': '酸辣汤',
      'dish_en': 'Hot and Sour Soup',
    },
    {
      'reason_zh': '周末了，犒劳一下自己吧',
      'reason_en': 'It\'s weekend, treat yourself',
      'dish_zh': '糖醋里脊',
      'dish_en': 'Sweet and Sour Pork',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
    _refreshRecommendation();
    _askLocationOnFirstLaunch();
  }

  Future<void> _askLocationOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('firstLaunch') ?? true;
    if (!firstLaunch) return;

    await prefs.setBool('firstLaunch', false);
    await _determinePosition();
  }


  // 请求位置权限并获取当前位置
  Future<bool> _requestLocationPermission() async {
    // GPS 服务是否开启
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final res = await Geolocator.openLocationSettings();
      if (!res) return false;
    }

    // 申请权限
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // 获取当前位置并保存到 SharedPreferences
  Future<void> _fetchCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('longitude', position.longitude);
    await prefs.setDouble('latitude', position.latitude);
  }

  Future<void> _determinePosition() async {
    final granted = await _requestLocationPermission();
    if (!granted) {
      // 如需引导用户手动开启可在这里处理
      return;
    }
    await _fetchCurrentLocation();
  }

  void _refreshRecommendation() {
    final random = Random();
    final index = random.nextInt(_recommendations.length);
    final rec = _recommendations[index];
    setState(() {
      _currentReason =
          _selectedLanguage == 'zh' ? rec['reason_zh']! : rec['reason_en']!;
      _recommendedDish =
          _selectedLanguage == 'zh' ? rec['dish_zh']! : rec['dish_en']!;
    });
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
    _refreshRecommendation();
  }

  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
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
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/images/logo.png',
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('appName'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            Text(
                              _selectedLanguage == 'zh'
                                  ? '今天想吃点什么？'
                                  : 'What do you want to eat?',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 1. 今日推荐 - 大卡片
                  _buildRecommendationCard(context, isDark),
                  const SizedBox(height: 16),

                  // 2. 两个并排的小卡片
                  Row(
                    children: [
                      Expanded(child: _buildRandomRecipeCard(context, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAIAssistantCard(context, isDark)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationCard(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _selectedLanguage == 'zh' ? '今日推荐' : 'For You',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _refreshRecommendation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _recommendedDish,
            style: TextStyle(
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentReason,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 跳转到菜谱详情
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedLanguage == 'zh' ? '查看做法' : 'View Recipe',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomRecipeCard(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RandomRecipePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.casino_rounded,
                color: Colors.orange.shade600,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'zh' ? '随机\n菜谱' : 'Random\nRecipe',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLanguage == 'zh' ? '让命运决定' : 'Let fate decide',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIAssistantPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.teal.shade600,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'zh' ? 'AI\n助手' : 'AI\nAssistant',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLanguage == 'zh' ? '智能推荐' : 'Smart advice',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
