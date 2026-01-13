import 'package:flutter/material.dart';


class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('关于我们'),
      ),
      body: Center(
        child: Text('这是关于我们页面'),
      ),
    );
  }
}