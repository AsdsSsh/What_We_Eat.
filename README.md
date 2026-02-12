# 吃了么(What We Eat)

What We Eat 是一款食材驱动的智能食谱推荐 App。

仍在开发中，功能尚未完善。

## 介绍

- **智能食材匹配**  
  勾选食材库中的食材，系统实时筛选可用菜谱。

- **个人食谱库**  
  收藏菜谱、记录作品。

- **周边搜索**  
  基于位置，搜索附近餐厅和食堂。

- **跨平台**  
  使用 Flutter 开发，能够将应用便捷地覆盖到多个不同平台

- **AI智能助手**  
  使用Function Calling , AI根据用户问题智能提供推荐与建议

- **离线使用**  
  基本功能可以离线使用。

## 技术栈

- 前端：Flutter(Dart) + Provider
- 后端：Gin(Go)
- 数据库：PostgreSQL + SQLite

## 外部API调用

| API | 描述 |
| :--: | :--: |
| DeepSeek API | 用于实现AI助手功能 |
| Openweather API | 为Function Calling 提供获取天气数据工具 |

## 启动

```bash
flutter run --dart-define=API_URL=https://yourhost.com
flutter build apk --dart-define=API_URL=https://yourhost.com
```

## 致谢

**智能食材匹配**灵感源自 [cook](https://github.com/YunYouJun/cook)
