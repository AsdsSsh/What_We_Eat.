import 'dart:convert';
import 'dart:ui';
import 'dart:math';
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

class _AIAssistantPageState extends State<AIAssistantPage>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String get _lang => appLanguageNotifier.value;

  static const String _apiUrl = '${ApiConfig.baseUrl}/api/recommend/call_ai';

  // ---- 动画 ----
  late AnimationController _entryController;
  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _bodyFade;
  late Animation<double> _inputSlide;

  // 加载动画
  late AnimationController _loadingDotController;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': _lang == 'zh'
          ? '你好！我是你的AI饮食助手。\n\n我可以帮你：\n• 根据你的口味推荐菜谱\n• 分析你的营养需求\n• 提供健康饮食建议\n\n请告诉我你的需求吧！'
          : 'Hello! I\'m your AI diet assistant.\n\nI can help you:\n• Recommend recipes based on your taste\n• Analyze your nutritional needs\n• Provide healthy eating advice\n\nTell me what you need!',
    });

    _initAnimations();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    ));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    ));
    _bodyFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));
    _inputSlide = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _entryController.forward();

    _loadingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang == 'zh' ? '请输入内容！' : 'Please enter a message!'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final reply = await _fetchAssistantReply(text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': reply});
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': _lang == 'zh'
              ? '请求失败，请稍后重试。'
              : 'Request failed, please try again later.',
        });
      });
      _scrollToBottom();
    }
  }

  Future<String> _fetchAssistantReply(String input) async {
    final resp = await http.post(
      Uri.parse(_apiUrl),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'Message': input}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Bad status: ${resp.statusCode}');
    }

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
    } catch (_) {}
    return body;
  }

  // ==================================================================
  //  BUILD
  // ==================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          body: AnimatedBuilder(
            animation: _entryController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A1A2E),
                            Color(0xFF16213E),
                            Color(0xFF0F3460),
                          ],
                          stops: [0.0, 0.3, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF0F4FF),
                            Color(0xFFE8F0FE),
                            Color(0xFFFFF8F0),
                          ],
                          stops: [0.0, 0.3, 1.0],
                        ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // ---- 顶栏 ----
                      Transform.translate(
                        offset: Offset(0, _headerSlide.value),
                        child: Opacity(
                          opacity: _headerFade.value,
                          child: _buildHeader(isDark),
                        ),
                      ),

                      // ---- 消息列表 ----
                      Expanded(
                        child: Opacity(
                          opacity: _bodyFade.value,
                          child: _buildMessageList(isDark),
                        ),
                      ),

                      // ---- 输入区 ----
                      Transform.translate(
                        offset: Offset(0, _inputSlide.value),
                        child: _buildInputArea(isDark),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================================================================
  //  顶栏 — 玻璃态 + 渐变装饰
  // ==================================================================
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // AI 头像 + 名称
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lang == 'zh' ? 'AI 饮食助手' : 'AI Diet Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.accentGreen.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _lang == 'zh' ? '在线' : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 右侧功能按钮
          _buildHeaderAction(
            isDark,
            Icons.refresh_rounded,
            () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': _lang == 'zh'
                      ? '对话已重置。有什么我可以帮你的吗？'
                      : 'Chat reset. How can I help you?',
                });
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(bool isDark, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? AppTheme.textSecondaryDark
              : AppTheme.textSecondaryLight,
        ),
      ),
    );
  }

  // ==================================================================
  //  消息列表
  // ==================================================================
  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == _messages.length) {
          return _buildLoadingBubble(isDark);
        }
        final message = _messages[index];
        final isUser = message['role'] == 'user';
        return _AnimatedMessageBubble(
          key: ValueKey('msg_$index'),
          index: index,
          child: _buildMessageBubble(message['content']!, isUser, isDark, index),
        );
      },
    );
  }

  // ==================================================================
  //  单条消息气泡
  // ==================================================================
  Widget _buildMessageBubble(
      String content, bool isUser, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 头像
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],

          // 气泡
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isUser ? 0 : 12,
                  sigmaY: isUser ? 0 : 12,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2D6CDF), Color(0xFF667eea)],
                          )
                        : (isDark
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.04),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.75),
                                  Colors.white.withValues(alpha: 0.55),
                                ],
                              )),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF2D6CDF).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                            listBullet: TextStyle(
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                            strong: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // 用户头像
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.orangeGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================================================================
  //  加载动画气泡 —— 三个跳动圆点
  // ==================================================================
  Widget _buildLoadingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _loadingDotController,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final delay = i * 0.2;
                        final t = (_loadingDotController.value - delay) % 1.0;
                        final bounce = sin(t * pi).clamp(0.0, 1.0);
                        return Container(
                          margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                          child: Transform.translate(
                            offset: Offset(0, -6 * bounce),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea)
                                        .withValues(alpha: 0.6 + 0.4 * bounce),
                                    const Color(0xFF764ba2)
                                        .withValues(alpha: 0.6 + 0.4 * bounce),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  //  底部输入区 — 玻璃态
  // ==================================================================
  Widget _buildInputArea(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.55),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // 输入框
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: _lang == 'zh'
                            ? '输入你的问题...'
                            : 'Type your question...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 20,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 36, minHeight: 0),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 发送按钮
                _SendButton(
                  onTap: _sendMessage,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _entryController.dispose();
    _loadingDotController.dispose();
    super.dispose();
  }
}

// =====================================================================
//  消息入场动画包装
// =====================================================================
class _AnimatedMessageBubble extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedMessageBubble({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 40).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// =====================================================================
//  发送按钮 — 渐变 + 缩放交互
// =====================================================================
class _SendButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _SendButton({required this.onTap, required this.isLoading});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withValues(alpha: 0.5),
                      const Color(0xFF764ba2).withValues(alpha: 0.5),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF667eea).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            widget.isLoading
                ? Icons.hourglass_top_rounded
                : Icons.send_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
