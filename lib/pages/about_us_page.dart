import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:what_we_eat/i18n/translations.dart';
import 'package:what_we_eat/pages/setting_page.dart';


class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t('PrivacyPolicy')),
          content: Text(
            t('privacyPolicyContent'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initLanguageFromPrefs();
  }
  String _selectedLanguage = 'zh';
  String t(String key) {
    return Translations.translate(key, _selectedLanguage);
  }

  Future<void> _initLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage') ?? 'zh';
    setState(() {
      _selectedLanguage = saved;
    });
    appLanguageNotifier.value = saved;
  }
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        _selectedLanguage = lang;
        return Scaffold(
          appBar: AppBar(
            title: Text(t('AboutUs')),
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
                                    t('appName'),
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
                          t('AppDescription'),
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
                    title: Text(t('ProjectAddress')),
                    subtitle: Text(t('ViewProjectSourceCode')),
                    trailing: Icon(Icons.open_in_new, color: Colors.blue.shade700),
                    onTap: () => _launchURL('https://github.com/AsdsSsh/What-should-we-eat-today-'),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Privacy Policy
                Text(
                  t('PrivacyPolicy'),
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
                    leading: Icon(Icons.privacy_tip_rounded, color: Colors.grey[700]),
                    title: Text(t('PrivacyPolicy')),
                    subtitle: Text(t('privacyPolicySubtitle')),
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.blue.shade700),
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                ),
                const SizedBox(height: 20),
                
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
    );
  }
}