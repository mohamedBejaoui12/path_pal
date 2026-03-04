import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../data/chatbot_provider.dart';
import '../domain/message_model.dart';
import '../../../shared/theme/app_colors.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    setState(() => _isTyping = true);

    await ref.read(chatHistoryProvider.notifier).sendMessage(message);

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Scroll to bottom when new messages are added
    if (chatHistory.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Colors.grey.shade800 // Grey in dark mode
            : AppColors.primaryColor, // Red in light mode
        foregroundColor: Colors.white, // White text for both modes
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/amSloma.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Am Slouma', style: TextStyle(fontSize: 16)),
                Text('Tunisia Expert', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text(
                      'Are you sure you want to clear the chat history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(chatHistoryProvider.notifier).clearChat();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: chatHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.network(
                          'https://assets1.lottiefiles.com/packages/lf20_Ht5zQs.json',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ask Am Slouma about Tunisia!',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = chatHistory[index];
                      return _MessageBubble(
                        message: message,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryColor,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/amSloma.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        WavyAnimatedText('Am Slouma is typing...'),
                      ],
                      isRepeatingAnimation: true,
                      repeatForever: true,
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about Tunisia...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: AppColors.primaryColor,
                    elevation: 0,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatbotMessage message;
  final bool isDarkMode;

  const _MessageBubble({
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time = DateFormat.jm().format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryColor,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/amSloma.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryColor
                    : isDarkMode
                        ? Colors.grey.shade800 // Darker background in dark mode
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser || isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser || isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.withOpacity(0.2),
              child: Icon(Icons.person,
                  color: isDarkMode ? Colors.white70 : Colors.grey, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
