# 🥬🍅 吃了么(What We Eat) — 用手边食材，解锁美味菜谱

What We Eat 是一款食材驱动的智能食谱推荐 App。勾选已有食材，App 智能匹配所有可做菜谱。

## 📱 功能

- **智能食材匹配**  
  勾选食材库中的食材，系统实时筛选可用菜谱。

- **个人食谱库**  
  收藏菜谱、记录作品。

- **周边搜索**  
  基于位置，搜索附近餐厅和食堂。

- **跨平台**  
  Flutter 开发，iOS 与 Android 流畅运行。

## 🛠 技术栈

- 前端：Flutter(Dart) + Provider
- 后端：Gin(Go)
- 数据库：PostgreSQL + SQLite
- MCP Server：[HowToCook-mcp](https://github.com/worryzyy/HowToCook-mcp.git)

## 🚀 启动

```bash
flutter run --dart-define=API_URL=https://yourhost.com
flutter build apk --dart-define=API_URL=https://yourhost.com
```

## 🙏 致谢

灵感源自 [cook](https://github.com/YunYouJun/cook)
