import 'dart:async';
import 'package:flutter/material.dart';
import 'package:f1/api/api_client.dart';

/// Race OS chat page
///
/// - Session-only chat history (resets on hot restart / app reload)
/// - Editable quick prompts
/// - Modern red / black / white UI
/// - Plug your Python backend into [_getAiResponse]
///
/// Usage:
/// MaterialApp(
///   debugShowCheckedModeBanner: false,
///   home: const RaceOsChatPage(),
/// )
class AichatTab extends StatefulWidget {
  const AichatTab({super.key});

  @override
  State<AichatTab> createState() => _AichatTabState();
}

class _AichatTabState extends State<AichatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage.ai(
      'Welcome to Race OS. Ask me anything about Formula 1 — drivers, teams, strategies, regulations, circuits, race weekends, or car tech.',
    ),
  ];

  final List<String> _quickPrompts = [
    'Explain the difference between overcut and undercut in F1.',
    'Compare Red Bull and Ferrari race strategy styles.',
    'Teach me F1 tire compounds like I am a beginner.',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? prompt]) async {
    final text = (prompt ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _getAiResponse(text);
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage.ai(response));
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage.ai(
            'Something went wrong while contacting Race OS. Please check your API setup or backend connection.\n\nError: $e',
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _getAiResponse(String userMessage) async {
    final apiClient = ApiClient();
    return await apiClient.chat(userMessage);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showAddPromptSheet() {
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Add Quick Prompt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter a new sample prompt...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1B1B1B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE10600),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final newPrompt = controller.text.trim();
                    if (newPrompt.isEmpty) return;
                    setState(() {
                      _quickPrompts.add(newPrompt);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Add Prompt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startNewChat() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage.ai(
            'New session started. Ask Race OS anything about Formula 1.',
          ),
        );
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF090909);
    const card = Color(0xFF141414);
    const softCard = Color(0xFF1A1A1A);
    const accent = Color(0xFFE10600);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 170, 18, 10),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [accent, Color(0xFF8C0000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Race OS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'F1 AI Copilot',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _startNewChat,
                          tooltip: 'New chat',
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Wrap(
                    //   spacing: 8,
                    //   runSpacing: 8,
                    //   children: [
                    //     _infoPill('Session chat only'),
                    //     _infoPill('No reload persistence'),
                    //     _infoPill('Red • Black • White'),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'Quick Prompts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAddPromptSheet,
                    icon: const Icon(Icons.add, color: accent, size: 18),
                    label: const Text(
                      'Add Prompt',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return GestureDetector(
                    onTap: () => _sendMessage(prompt),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: softCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.north_east_rounded,
                            color: accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              prompt,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: _quickPrompts.length,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return const _TypingBubble();
                    }

                    final message = _messages[index];
                    final isUser = message.role == _MessageRole.user;

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? accent : softCard,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 6),
                            bottomRight: Radius.circular(isUser ? 6 : 18),
                          ),
                          border: Border.all(
                            color: isUser
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.45,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask Race OS anything about Formula 1...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.white24 : accent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final phase = _controller.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final opacity = ((phase + (index * 0.2)) % 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.35 + (opacity * 0.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

enum _MessageRole { user, ai }

class _ChatMessage {
  final String text;
  final _MessageRole role;

  const _ChatMessage({required this.text, required this.role});

  factory _ChatMessage.user(String text) {
    return _ChatMessage(text: text, role: _MessageRole.user);
  }

  factory _ChatMessage.ai(String text) {
    return _ChatMessage(text: text, role: _MessageRole.ai);
  }
}
