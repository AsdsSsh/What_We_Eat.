import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';




class BottomNavBar extends StatelessWidget {

  final Function(int)? onTabChange;
  final int selectedIndex;
  BottomNavBar({super.key , required this.onTabChange, required this.selectedIndex});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GNav(
        color: Colors.grey[400],
        selectedIndex: selectedIndex,
        activeColor: Colors.grey.shade700,
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 25,
        onTabChange: (value) => onTabChange!(value),
        tabs: const [
          GButton(
            icon: Icons.home,
            text: '首页',
          ),
          GButton(
            icon: Icons.restaurant_menu,
            text: '做菜!',
          ),
          GButton(
            icon: Icons.search,
            text: '搜索',
          ),
        ]
      ),
    );
  }
}