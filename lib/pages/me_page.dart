import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/pages/about_us_page.dart';
import 'package:what_we_eat/pages/feedback_page.dart';


class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color.fromARGB(255, 47, 106, 209),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_circle,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '美食爱好者',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '探索美食，享受生活',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '已使用 15 次',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Menu Section
            Text(
              '功能菜单',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),

            // Settings
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.settings, color: Colors.blue.shade700),
                title: const Text('设置'),
                subtitle: const Text('应用偏好设置'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // About Us
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.blue.shade700),
                title: const Text('关于我们'),
                subtitle: const Text('了解应用信息'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Other options section
            Text(
              '其他',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),

            // Feedback
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.feedback, color: Colors.orange.shade700),
                title: const Text('意见反馈'),
                subtitle: const Text('帮助我们改进应用'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackPage()),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Version
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: const ListTile(
                leading: Icon(Icons.history, color: Colors.grey),
                title: Text('版本号'),
                subtitle: Text('v0.0.3'),
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                '© 2024 今天吃什么？',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}