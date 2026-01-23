import 'package:flutter/material.dart';
class MyfavoritePage extends StatefulWidget {
  const MyfavoritePage({super.key});

  @override
  State<MyfavoritePage> createState() => _MyfavoritePageState();
}

class _MyfavoritePageState extends State<MyfavoritePage> {
  @override
  Widget build(BuildContext context) {
     return  Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          '收藏',
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