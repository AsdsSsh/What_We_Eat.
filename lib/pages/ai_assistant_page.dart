import 'package:flutter/material.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String get _lang => appLanguageNotifier.value;

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _messages.add({
      'role': 'assistant',
      'content': _lang == 'zh' 
          ? '你好！我是你的AI饮食助手。\n\n我可以帮你：\n• 根据你的口味推荐菜谱\n• 分析你的营养需求\n• 提供健康饮食建议\n\n请告诉我你的需求吧！'
          : 'Hello! I\'m your AI diet assistant.\n\nI can help you:\n• Recommend recipes based on your taste\n• Analyze your nutritional needs\n• Provide healthy eating advice\n\nTell me what you need!',
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _inputController.clear();

    // 模拟AI回复
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': _generateMockResponse(text),
        });
      });
    });
  }

  String _generateMockResponse(String input) {
    // 模拟AI回复
    if (input.contains('减肥') || input.contains('diet') || input.contains('lose weight')) {
      return _lang == 'zh'
          ? '根据您的减肥需求，我推荐以下低卡菜谱：\n\n1. **清蒸鱼** - 高蛋白低脂肪\n2. **凉拌黄瓜** - 清爽解腻\n3. **西兰花炒虾仁** - 营养均衡\n\n建议每餐控制在400-500卡路里，多喝水，适量运动。'
          : 'Based on your diet needs, I recommend:\n\n1. **Steamed Fish** - High protein, low fat\n2. **Cucumber Salad** - Refreshing\n3. **Broccoli with Shrimp** - Balanced nutrition\n\nKeep each meal around 400-500 calories, drink more water, and exercise regularly.';
    } else if (input.contains('营养') || input.contains('nutrition') || input.contains('健康')) {
      return _lang == 'zh'
          ? '健康饮食建议：\n\n• 每天摄入足够的蔬菜水果\n• 蛋白质来源多样化（肉、蛋、豆类）\n• 减少油炸和高糖食物\n• 保持规律的用餐时间\n\n需要我为您定制一周的营养餐单吗？'
          : 'Healthy eating tips:\n\n• Eat enough vegetables and fruits daily\n• Diversify protein sources (meat, eggs, legumes)\n• Reduce fried and high-sugar foods\n• Maintain regular meal times\n\nWould you like me to create a weekly meal plan for you?';
    } else {
      return _lang == 'zh'
          ? '我理解您的需求。根据您的描述，我建议您可以尝试一些家常菜，比如：\n\n• 番茄炒蛋 - 简单美味\n• 蒜蓉西兰花 - 健康营养\n• 红烧豆腐 - 经济实惠\n\n您还有其他问题吗？'
          : 'I understand your needs. Based on your description, I suggest trying some home-cooked dishes:\n\n• Tomato Scrambled Eggs - Simple and delicious\n• Garlic Broccoli - Healthy and nutritious\n• Braised Tofu - Economical\n\nDo you have any other questions?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_lang == 'zh' ? 'AI饮食助手' : 'AI Diet Assistant'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              // 消息列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return _buildLoadingBubble(isDark);
                    }
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';
                    return _buildMessageBubble(message['content']!, isUser, isDark);
                  },
                ),
              ),

              // 输入框
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: _lang == 'zh' ? '输入你的问题...' : 'Type your question...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser ? AppTheme.primaryGradient : null,
          color: isUser ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _lang == 'zh' ? '思考中...' : 'Thinking...',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
