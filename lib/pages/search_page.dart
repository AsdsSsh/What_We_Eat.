import 'package:flutter/material.dart';



class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: Center(
        child: Text('这是搜索页面'),
      ),
    );
  }
}