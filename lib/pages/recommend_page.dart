import 'package:flutter/material.dart';
class RecommendPage extends StatelessWidget {
  const RecommendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          '推荐',
          style: TextStyle(color: Colors.black),
        )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      )
      );
  }
}