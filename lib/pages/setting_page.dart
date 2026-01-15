import 'package:flutter/material.dart';



class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        backgroundColor: Color.fromARGB(255, 47, 106, 209),
      ),
      body: Center(
        child: Text('这是设置页面'),
      ),
    );
  }
}