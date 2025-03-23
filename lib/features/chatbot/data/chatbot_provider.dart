import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chatbot_service.dart';
import '../domain/message_model.dart';

final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});

final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, List<ChatbotMessage>>((ref) {
  return ChatHistoryNotifier(ref);
});

class ChatHistoryNotifier extends StateNotifier<List<ChatbotMessage>> {
  final Ref ref;

  ChatHistoryNotifier(this.ref) : super([
    // Initial welcome message
    ChatbotMessage(
      text: "Ahla! I'm Am Slouma, your Tunisian guide. Ask me anything about Tunisia - from the best beaches to visit, traditional cuisine to try, or historical sites to explore!",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to state
    final userMessage = ChatbotMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    state = [...state, userMessage];

    // Get response from chatbot
    final chatbotService = ref.read(chatbotServiceProvider);
    final response = await chatbotService.sendMessage(message);
    
    // Add chatbot response to state
    state = [...state, response];
  }

  void clearChat() {
    state = [
      // Reset to initial welcome message
      ChatbotMessage(
        text: "Ahla! I'm Am Slouma, your Tunisian guide. Ask me anything about Tunisia - from the best beaches to visit, traditional cuisine to try, or historical sites to explore!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}