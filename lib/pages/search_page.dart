import 'package:flutter/material.dart';



class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.0),
          margin: EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.grey[100] , 
            borderRadius: BorderRadius.circular(8)
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索',
                style: TextStyle(color: Colors.grey),
                ),
              Icon(Icons.search),
            ],
          ),
        )
      ]
    );
  }
}