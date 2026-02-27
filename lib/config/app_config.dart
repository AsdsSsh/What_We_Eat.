/// 应用全局配置
class AppConfig {
  // 禁止实例化
  AppConfig._();

  /// 应用版本号
  static const String version = '0.0.2';
  
  /// 应用构建号
  static const String buildNumber = '1';
  
  /// 完整版本信息 (用于显示)
  static const String fullVersion = 'v$version';
  
  /// 商标显示
  static  const String trademark = '© 2026 吃了么';

  /// 版本显示文本 (中文)
  static const String versionText = '版本 $version';
  
  /// 应用名称
  static const String appName = '吃了么';
  
  /// 应用描述
  static const String appDescription = '用你手边的食材，解锁万千美味';

  /// 用户收藏同步间隔（分钟）
  static const int favoriteSyncIntervalMinutes = 5;
}
