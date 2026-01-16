import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // 总时长：2.5秒
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 透明度动画：0 → 1（前40%），保持1（中间20%），1 → 0（后40%）
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 4), // 淡入
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2),          // 停留
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 4), // 淡出
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // 缩放动画：
    // 淡入和停留阶段：保持 1.0（不缩放）
    // 淡出阶段：1.0 → 0.6（轻微收缩）
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 6), // 前60%：不变
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 4), // 后40%：收缩
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // 动画结束后跳转
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0078D4),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 250,
                  height: 250,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}