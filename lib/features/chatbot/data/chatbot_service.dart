import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../domain/message_model.dart';

class ChatbotService {
  late final GenerativeModel _model;
  ChatSession? _chatSession; 

  ChatbotService() {
    _initializeModel();
  }

  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: GeminiConfig.modelName,
        apiKey: GeminiConfig.apiKey,
      );

    } catch (e) {
      debugPrint('Error initializing Gemini model: $e');
      rethrow;
    }
  }

  Future<void> _initializeChat() async {
    try {
      final systemPrompt = Content.text(GeminiConfig.systemPrompt);

      _chatSession = _model.startChat(
        history: [systemPrompt],
      );
    } catch (e) {
      debugPrint('Error initializing chat session: $e');
      rethrow;
    }
  }

  Future<ChatbotMessage> sendMessage(String message) async {
    try {
      if (_chatSession == null) {
        await _initializeChat();
      }

      if (_chatSession == null) {
        throw Exception('Failed to initialize chat session');
      }

      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );

      final responseText =
          response.text ?? 'Sorry, I couldn\'t generate a response.';

      return ChatbotMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      
      String errorMessage;
      if (e.toString().contains('503') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'The AI service is currently unavailable. Please try again later.';
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'The session has expired. Please restart the chat.';
        _chatSession = null;
      } else {
        errorMessage = 'Sorry, I encountered an error. Please try again later.';
      }
      
      return ChatbotMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}
