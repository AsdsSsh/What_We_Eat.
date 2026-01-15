import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
        backgroundColor: const Color.fromARGB(255, 47, 106, 209),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Introduction
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu, size: 32, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今天吃什么？',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                              ),
                              Text(
                                'v0.0.2',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '一款帮助你快速决策今天吃什么的应用。提供智能推荐、一键做菜指南以及快速菜谱搜索功能。',
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // GitHub Link
            Text(
              '项目地址',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.code, color: Colors.grey[700]),
                title: const Text('GitHub Repository'),
                subtitle: const Text('查看项目源代码'),
                trailing: Icon(Icons.open_in_new, color: Colors.blue.shade700),
                onTap: () => _launchURL('https://github.com/AsdsSsh/What-should-we-eat-today-'),
              ),
            ),
            const SizedBox(height: 20),
            
            // // Developers Section
            // Text(
            //   '开发团队',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.grey[900],
            //   ),
            // ),
            // const SizedBox(height: 12),
            // _buildDeveloperCard(
            //   name: '开发者 1',
            //   role: '全栈开发者',
            //   description: '负责应用的整体架构和功能开发。',
            //   icon: Icons.person,
            // ),
            // const SizedBox(height: 12),
            // _buildDeveloperCard(
            //   name: '开发者 2',
            //   role: 'UI/UX 设计师',
            //   description: '设计应用界面和用户体验。',
            //   icon: Icons.palette,
            // ),
            // const SizedBox(height: 20),
            
            // Footer
            Center(
              child: Text(
                '感谢你使用本应用！',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}