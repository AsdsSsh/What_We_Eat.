import 'package:flutter/material.dart';


class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的'),
      ),
      body: Center(
        child: Text('这是我的页面'),
      ),
    );
  }
}