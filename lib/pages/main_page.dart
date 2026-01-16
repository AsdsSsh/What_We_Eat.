import 'package:flutter/material.dart';
import 'package:what_we_eat/components/bottom_nav_bar.dart';
import 'package:what_we_eat/pages/do_dish_page.dart';
import 'package:what_we_eat/pages/home_page.dart';
import 'package:what_we_eat/pages/me_page.dart';
import 'package:what_we_eat/pages/search_page.dart';
import 'package:what_we_eat/pages/setting_page.dart';


class MainPage extends StatefulWidget {
  

  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {

  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onExplore: () => _onItemTapped(1)),
      DoDishPage(),
      const SearchPage(),
    ];
  }

  void _onItemTapped(int index) {
    // animate to page if controller attached, otherwise just update index
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = index;
    });
    
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
              child: Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  height: 300,
                  color: Colors.white,
                ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('首页'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);

              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('设置'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('我的'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MePage())
                );
              },
            )
          ]
        ),
      ),
      appBar: AppBar(
        // title: Center(child: Text('今天吃什么？')),
        backgroundColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        onTabChange: (index) =>_onItemTapped(index),
        selectedIndex: _selectedIndex,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),

    );
  }
}