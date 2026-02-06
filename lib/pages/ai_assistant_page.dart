import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:what_we_eat/config/api_config.dart';
import 'package:what_we_eat/pages/setting_page.dart';
import 'package:what_we_eat/theme/app_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;

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

  static const String _apiUrl = '${ApiConfig.baseUrl}/api/recommend/call_ai';

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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      // 提示用户输入内容
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_lang == 'zh' ? '请输入内容！' : 'Please enter a message!')),
      );
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _inputController.clear();

    try {
      final reply = await _fetchAssistantReply(text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': _lang == 'zh' ? '请求失败，请稍后重试。' : 'Request failed, please try again later.',
        });
      });
    }
  }

  Future<String> _fetchAssistantReply(String input) async {
    final resp = await http.post(
      Uri.parse(_apiUrl),
      headers: const {'Content-Type': 'application/json' , 'Accept': 'application/json'},
      body: jsonEncode({'Message': input}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Bad status: ${resp.statusCode}');
    }

    // 兼容 JSON 或纯文本返回
    final body = resp.body.trim();
    if (body.isEmpty) {
      return _lang == 'zh' ? '没有收到有效回复。' : 'No valid response.';
    }

    try {
      final data = jsonDecode(body);
      if (data is Map && data['response'] is String) {
        return data['response'] as String;
      }
      if (data is Map && data['content'] is String) {
        return data['content'] as String;
      }
      if (data is String) return data;
    } catch (_) {
      // 非 JSON，按纯文本处理
    }
    return body;
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
        child: isUser ? Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
            fontSize: 15,
            height: 1.4,
          ),
        ) : MarkdownBody(data: content)
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
