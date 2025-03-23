class ChatbotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}