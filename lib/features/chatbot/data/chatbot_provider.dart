import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chatbot_service.dart';
import '../domain/message_model.dart';

final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});

final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<ChatbotMessage>>((ref) {
  return ChatHistoryNotifier(ref);
});

class ChatHistoryNotifier extends StateNotifier<List<ChatbotMessage>> {
  final Ref ref;
  late final ChatbotService _chatbotService;

  ChatHistoryNotifier(this.ref)
      : super([
          ChatbotMessage(
            text:
                "Ahla! I'm Am Slouma, your Tunisian guide. Ask me anything about Tunisia - from the best beaches to visit, traditional cuisine to try, or historical sites to explore!",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]) {
    _chatbotService = ref.read(chatbotServiceProvider);
  }

  Future<void> sendMessage(String message) async {
    final userMessage = ChatbotMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = [...state, userMessage];

    try {
      final botResponse = await _chatbotService.sendMessage(message);
      state = [...state, botResponse];
    } catch (e) {
      final errorMessage = ChatbotMessage(
        text:
            'The AI service is currently unavailable. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMessage];
    }
  }

  void clearChat() {
    state = [
      ChatbotMessage(
        text:
            "Ahla! I'm Am Slouma, your Tunisian guide. Ask me anything about Tunisia - from the best beaches to visit, traditional cuisine to try, or historical sites to explore!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}
