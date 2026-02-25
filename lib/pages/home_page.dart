import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/models/food.dart';
import 'package:what_we_eat/pages/ai_assistant_page.dart';
import 'package:what_we_eat/pages/random_recipe_page.dart';
import 'package:what_we_eat/pages/recipe_detail_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/providers/auth_provider.dart';
import 'package:what_we_eat/services/recommend_service.dart';
import 'package:what_we_eat/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

// ---------------------------------------------------------------------------
// 自定义页面过渡：iOS 风格滑入 + 淡入
// ---------------------------------------------------------------------------
class _SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  _SlideFadeRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position:
                  Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

// ---------------------------------------------------------------------------
// 浮动装饰粒子（背景氛围）
// ---------------------------------------------------------------------------
class _FloatingOrb {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double speed;
  _FloatingOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.speed,
  });
}

class _OrbsPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double tick;
  _OrbsPainter({required this.orbs, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final dx = orb.x * size.width +
          sin(tick * orb.speed) * 18;
      final dy = orb.y * size.height +
          cos(tick * orb.speed * 0.8) * 14;
      final paint = Paint()
        ..color = orb.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.8);
      canvas.drawCircle(Offset(dx, dy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) => old.tick != tick;
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  final VoidCallback? onExplore;
  const HomePage({super.key, this.onExplore});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _selectedLanguage = 'zh';
  String _recommendedDish = '';
  String _recommendedDescription = '';
  Food? _currentRecommendation;

  // ---- 动画控制器 ----
  late AnimationController _staggerController;
  late AnimationController _refreshSpinController;
  late AnimationController _orbController;
  late AnimationController _dishFadeController;

  // 入场动画
  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _smallCardSlide;
  late Animation<double> _smallCardFade;

  // 菜名切换动画
  late Animation<double> _dishFade;

  List<Food> _recommendations = [];

  // 浮动光球
  late List<_FloatingOrb> _orbs;

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
    _refreshRecommendation(animate: false);
    _askLocationOnFirstLaunch();
    _initAnimations();
    _initOrbs();
    _initRecommendations();
  }


  Future<void> _initRecommendations() async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final recommendations =
          await RecommendService.getRecommendFoods(userId: userId);
      setState(() {
        _recommendations = recommendations;
      });
      _refreshRecommendation(animate: false);
    } catch (e) {
      debugPrint('Failed to load recommendations: $e');
    }
  }


  // ---- 初始化浮动光球 ----
  void _initOrbs() {
    final rng = Random();
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    _orbs = List.generate(6, (i) {
      return _FloatingOrb(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.8,
        radius: 60 + rng.nextDouble() * 100,
        color: [
          AppTheme.primaryColor,
          AppTheme.accentOrange,
          AppTheme.accentGreen,
          Colors.purple,
          Colors.cyan,
          Colors.pinkAccent,
        ][i]
            .withValues(alpha: isDark ? 0.12 : 0.13),
        speed: 0.3 + rng.nextDouble() * 0.5,
      );
    });
  }

  // ---- 动画初始化 ----
  void _initAnimations() {
    // 交错入场
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    ));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    ));

    _cardSlide = Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    ));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
    ));

    _smallCardSlide = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    ));
    _smallCardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    ));

    _staggerController.forward();

    // 刷新按钮旋转
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 浮动光球
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // 菜名切换淡入淡出
    _dishFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    _dishFade = CurvedAnimation(
      parent: _dishFadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _refreshSpinController.dispose();
    _orbController.dispose();
    _dishFadeController.dispose();
    super.dispose();
  }

  // ---- 位置权限 ----
  Future<void> _askLocationOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('firstLaunch') ?? true;
    if (!firstLaunch) return;
    await prefs.setBool('firstLaunch', false);
    await _determinePosition();
  }

  Future<bool> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final res = await Geolocator.openLocationSettings();
      if (!res) return false;
    }
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

  Future<void> _fetchCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('longitude', position.longitude);
    await prefs.setDouble('latitude', position.latitude);
  }

  Future<void> _determinePosition() async {
    final granted = await _requestLocationPermission();
    if (!granted) return;
    await _fetchCurrentLocation();
  }

  // ---- 推荐刷新 ----
  void _refreshRecommendation({bool animate = true}) {
    if (_recommendations.isEmpty) return;
    final random = Random();
    final index = random.nextInt(_recommendations.length);
    final rec = _recommendations[index];
    final dishName = rec.name;
    final dishDescription = rec.description;

    if (animate) {
      _refreshSpinController.forward(from: 0);
      _dishFadeController.reverse().then((_) {
        setState(() {
          _recommendedDish = dishName;
          _recommendedDescription = dishDescription;
          _currentRecommendation = rec;
        });
        _dishFadeController.forward();
      });
    } else {
      setState(() {
        _recommendedDish = dishName;
        _recommendedDescription = dishDescription;
        _currentRecommendation = rec;
      });
    }
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() => _selectedLanguage = saved);
    appLanguageNotifier.value = saved;
    _refreshRecommendation(animate: false);
  }

  String t(String key) => Translations.translate(key, _selectedLanguage);

  // ---- 时间问候 ----
  String _greeting() {
    final hour = DateTime.now().hour;
    if (_selectedLanguage == 'zh') {
      if (hour < 6) return '夜深了，注意休息 🌙';
      if (hour < 11) return '早上好，活力满满 ☀️';
      if (hour < 14) return '中午好，该吃午饭了 🍱';
      if (hour < 18) return '下午好，来点小食？ 🍰';
      return '晚上好，今天想吃点什么？ 🌆';
    } else {
      if (hour < 6) return 'Late night, take care 🌙';
      if (hour < 11) return 'Good morning! ☀️';
      if (hour < 14) return 'Good afternoon, lunchtime 🍱';
      if (hour < 18) return 'Good afternoon, snack time? 🍰';
      return 'Good evening, what to eat? 🌆';
    }
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: AnimatedBuilder(
            animation: _staggerController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A1A2E),
                            Color(0xFF16213E),
                            Color(0xFF0F3460),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF0F4FF),
                            Color(0xFFE8F0FE),
                            Color(0xFFFFF3E6),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                ),
                child: Stack(
                children: [
                  // 背景浮动光球
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _orbController,
                      builder: (ctx, __) => CustomPaint(
                        painter: _OrbsPainter(
                          orbs: _orbs,
                          tick: _orbController.value * 2 * pi,
                        ),
                      ),
                    ),
                  ),

                  // 主内容
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- Header（交错动画） ----
                          Transform.translate(
                            offset: Offset(0, _headerSlide.value),
                            child: Opacity(
                              opacity: _headerFade.value,
                              child: _buildHeader(isDark),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ---- 今日推荐卡片 ----
                          Transform.translate(
                            offset: Offset(0, _cardSlide.value),
                            child: Opacity(
                              opacity: _cardFade.value,
                              child: _buildGlassRecommendationCard(
                                  context, isDark),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ---- 两个小卡片 ----
                          Transform.translate(
                            offset: Offset(0, _smallCardSlide.value),
                            child: Opacity(
                              opacity: _smallCardFade.value,
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildGlassFeatureCard(
                                    context,
                                    isDark,
                                    icon: Icons.casino_rounded,
                                    gradient: AppTheme.orangeGradient,
                                    accentColor: Colors.orange,
                                    title: _selectedLanguage == 'zh'
                                        ? '随机菜谱'
                                        : 'Random Recipe',
                                    subtitle: _selectedLanguage == 'zh'
                                        ? '让命运决定'
                                        : 'Let fate decide',
                                    onTap: () => Navigator.push(
                                      context,
                                      _SlideFadeRoute(
                                          page: const RandomRecipePage()),
                                    ),
                                  )),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: _buildGlassFeatureCard(
                                    context,
                                    isDark,
                                    icon: Icons.smart_toy_rounded,
                                    gradient: AppTheme.greenGradient,
                                    accentColor: Colors.teal,
                                    title: _selectedLanguage == 'zh'
                                        ? 'AI 助手'
                                        : 'AI Assistant',
                                    subtitle: _selectedLanguage == 'zh'
                                        ? '智能推荐'
                                        : 'Smart advice',
                                    onTap: () => Navigator.push(
                                      context,
                                      _SlideFadeRoute(
                                          page: const AIAssistantPage()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ---- 快捷提示条 ----
                          Transform.translate(
                            offset: Offset(0, _smallCardSlide.value * 0.6),
                            child: Opacity(
                              opacity: _smallCardFade.value,
                              child: _buildQuickTipBanner(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        );
      },
    );
  }

  // =====================================================================
  //  HEADER
  // =====================================================================
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // 品牌 logo — 带微光环
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Image.asset('assets/images/logo.png', color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('appName'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _greeting(),
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
    );
  }

  // =====================================================================
  //  玻璃态推荐卡片
  // =====================================================================
  Widget _buildGlassRecommendationCard(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          decoration: BoxDecoration(
            // 玻璃态：半透明背景 + 边框高光
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部彩色渐变装饰条
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryLight,
                      AppTheme.accentOrange,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // 标签 + 刷新
              Row(
                children: [
                  // 标签胶囊
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _selectedLanguage == 'zh' ? '今日推荐' : 'For You',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 旋转刷新按钮
                  _buildAnimatedRefreshButton(isDark),
                ],
              ),
              const SizedBox(height: 22),

              // 菜名 — 带淡入淡出
              FadeTransition(
                opacity: _dishFade,
                child: Text(
                  _recommendedDish,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _dishFade,
                child: Text(
                  _recommendedDescription.isNotEmpty
                      ? _recommendedDescription
                      : (_selectedLanguage == 'zh'
                          ? '暂无描述'
                          : 'No description yet'),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CTA 按钮 — 渐变 + 点击缩放
              _AnimatedGradientButton(
                label: _selectedLanguage == 'zh' ? '查看做法' : 'View Recipe',
                gradient: AppTheme.primaryGradient,
                onPressed: () {
                  final recipe = _currentRecommendation;
                  if (recipe == null) return;
                  Navigator.push(
                    context,
                    _SlideFadeRoute(
                      page: RecipeDetailPage(recipeInfo: recipe),
                    ),
                  );
                },
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 旋转的刷新按钮 ----
  Widget _buildAnimatedRefreshButton(bool isDark) {
    return GestureDetector(
      onTap: () => _refreshRecommendation(),
      child: AnimatedBuilder(
        animation: _refreshSpinController,
        builder: (ctx, child) {
          return Transform.rotate(
            angle: _refreshSpinController.value * 2 * pi,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            size: 20,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  //  玻璃态功能卡片（随机菜谱 / AI 助手）
  // =====================================================================
  Widget _buildGlassFeatureCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required LinearGradient gradient,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _TapScaleCard(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? accentColor.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标 — 渐变背景
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _selectedLanguage == 'zh' ? '前往' : 'Go',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: accentColor, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  //  快捷提示条
  // =====================================================================
  Widget _buildQuickTipBanner(bool isDark) {
    final tips = _selectedLanguage == 'zh'
        ? [
            '青青高槐叶，采掇付中厨。新面来近市，汁滓宛相俱',
            '每日三餐营养均衡最重要',
            'AI 助手可以根据你的口味推荐',
            '切肉的方式反映了你的生活态度',
            '告诉我你吃什么，我就能告诉你是什么样的人',
            '没有比热爱食物更真诚的爱',
            '⚙️ 赞美欧姆尼赛亚!!!!!'
          ]
        : [
            'The lush green leaves of tall locust trees,\nAre picked and sent to the kitchen with ease.\nFresh flour from the market near is brought,\nJuice and dregs, as if blending as they ought.',
            'A balanced diet matters most',
            'AI assistant recommends by your taste',
            'The way you cut your meat reflects the way you live',
            'Tell me what you eat, and I will tell you what you are',
            'There is no love sincerer than the love of food',
            '⚙️ Praise the Omnissiah!!!'
          ];
    final tip = tips[DateTime.now().second % tips.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.accentOrange.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.accentOrange.withValues(alpha: 0.06),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : AppTheme.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textPrimaryLight,
                    height: 1.4,
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

// =======================================================================
//  渐变 CTA 按钮（带按下缩放）
// =======================================================================
class _AnimatedGradientButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onPressed;

  const _AnimatedGradientButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================================
//  点击缩放包装卡片
// =======================================================================
class _TapScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScaleCard({required this.child, required this.onTap});

  @override
  State<_TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<_TapScaleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
