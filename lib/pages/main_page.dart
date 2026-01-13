import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/about_us_page.dart';
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

  final List _pages = [
    const HomePage(),
    const SearchPage(),
    const MePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
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
                color: Color.fromARGB(255, 47, 106, 209),
              ),
              child: Text(
                '菜单',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                )
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
              leading: Icon(Icons.developer_board),
              title: Text('关于我们'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage())
                );
              },
            )
          ]
        ),
      ),
      appBar: AppBar(
        title: Center(child: Text('今天吃什么？')),
        backgroundColor: const Color.fromARGB(255, 47, 106, 209),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}