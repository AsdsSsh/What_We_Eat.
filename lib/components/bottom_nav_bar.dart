import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int)? onTabChange;
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    required this.onTabChange,
    required this.selectedIndex,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String _selectedLanguage = 'zh';

  String t(String key) => Translations.translate(key, _selectedLanguage);

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() => _selectedLanguage = saved);
    appLanguageNotifier.value = saved;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _selectedLanguage = lang;

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.6),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.9),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _NavItem(
                          index: 0,
                          selectedIndex: widget.selectedIndex,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: t('home'),
                          isDark: isDark,
                          onTap: widget.onTabChange,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          index: 1,
                          selectedIndex: widget.selectedIndex,
                          icon: Icons.restaurant_menu_outlined,
                          activeIcon: Icons.restaurant_menu_rounded,
                          label: t('cook'),
                          isDark: isDark,
                          onTap: widget.onTabChange,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          index: 2,
                          selectedIndex: widget.selectedIndex,
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search_rounded,
                          label: t('search'),
                          isDark: isDark,
                          onTap: widget.onTabChange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
//  单个导航项 — 带缩放 + 渐变高亮
// =====================================================================
class _NavItem extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isDark;
  final Function(int)? onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  bool get _isSelected => widget.selectedIndex == widget.index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call(widget.index);
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: _isSelected ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: _isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isSelected
                ? [
                    BoxShadow(
                      color:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标（选中时用渐变着色）
              _isSelected
                  ? ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Icon(
                        widget.activeIcon,
                        size: 24,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      size: 24,
                      color: widget.isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),

              // 标签（选中时展开）
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
