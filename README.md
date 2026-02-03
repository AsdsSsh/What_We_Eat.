# 🥬🍅 吃了么(What We Eat) — 用你手边的食材，解锁万千美味

What We Eat 是一款以 “食材驱动” 为核心的智能食谱推荐 App。
不再盲目搜索菜名，只需勾选你手头已有的食材，App 即可智能匹配出你能做的全部菜谱——减少浪费、节省开支、激发烹饪灵感！

## 📱 功能

- 智能食材匹配引擎  
  用户从常用食材库中勾选（如：鸡蛋、土豆、牛肉、豆腐…），系统实时筛选出所有可用这些食材制作的食谱。

- 个人食谱库
  收藏常用菜谱、记录成功作品。

- 联网搜索扩展  
  基于用户当前位置，通过地图 API（如高德、百度、Google Maps）实时搜索附近提供相关菜品的食堂或餐厅。

- 跨平台体验  
  使用跨平台框架`Fluter`,一套代码，流畅运行于 iOS 与 Android，界面简洁、操作直观、启动迅速。

## 🛠 技术实现

- 前端: Flutter(Dart) + Provider 状态管理
- 后端: Gin(Go)
- 数据库: PostgreSQL + SQLite
- MCP Server 基于[**HowToCook-mcp**](https://github.com/worryzyy/HowToCook-mcp.git)

## 🚀启动

- Flutter启动: `flutter run --dart-define=API_URL=https://yourhost.com`
- 打包: `flutter build apk --dart-define=API_URL=https://yourhost.com`

## 🙏 灵感来源

本项目的“食材匹配食谱”的灵感源自开源项目 [**cook**](https://github.com/YunYouJun/cook)
