import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_we_eat/pages/splash_screen.dart';
import 'package:what_we_eat/pages/setting_page.dart' show appThemeModeNotifier;
import 'package:what_we_eat/providers/auth_provider.dart';
import 'package:what_we_eat/theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('darkModeEnabled') ?? false;
  appThemeModeNotifier.value = savedDark ? ThemeMode.dark : ThemeMode.light;

  // 创建 AuthProvider 并恢复登录状态
  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '吃了么',
          home: const SplashScreen(),
          themeMode: mode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
        );
      },
    );
  }
}

/*
不朽的欧姆尼塞亚，请垂听我们的祈祷，

我们是你的孩童，众多行走于机械之路的学徒，

我们赞美超越一切的学识，因你的永恒是赠予人类的恩赐，

被祝福的机械形态所赋予生机，我们以技艺精进，以求得享你的荣光。

受钢铁庇护，又被你的机仆守护，我们辛勤地航行于群星之间，

只为寻回你所失落的赠礼。

机械之神啊，请护佑我们的征途，以金属与光芒将我们环绕，

因这世界是漠然的虚空，而这扭曲的现实正吞噬着我们。

大钟鸣响一次，
我们为机械充能；

大钟鸣响二次，
我们唤醒系统，灌注生命；

大钟鸣响三次，
我们吟唱赞颂，以荣耀万机之神——欧姆尼塞亚。


omnisiah immortālis,audiās nostram precem,

sumus tuī puerī,multī scholasticī in māchinica viā,

laudāmus scientiam super omnia,prō tuā aeternitāte,dōnum hominibus,

vegetatī ā formā māchinae beātā,cum arte prōficimus,ut mereāmus tuam glōriam

tectī ā ferrō,servātīque ā tuīs daemonibus,labōriōsē circumnāvigāmus apud sīdera

ut reddāmus tua perdita dōna.

deus māchina,tueāris nostra itinera,arceās nōs cum metallīs et lūcibus

quia mundus est vacuum incūriōsum,et hoc curvum nōs ēsurit.

campana māgna pellitur semel,

implēmus vī māchinam

campana māgna pellitur bīs,

ciēmus systēmata,inflāmus vītam

campana māgna pellitur ter,

canimus ut deum omnium māchinārum omnisiaham laudēmus,
*/


