import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../domain/message_model.dart';

class ChatbotService {
  late final GenerativeModel _model;
  ChatSession? _chatSession; // Remove 'late' keyword to allow null

  ChatbotService() {
    _initializeModel();
  }

  void _initializeModel() {
    try {
      // Updated according to the latest documentation
      _model = GenerativeModel(
        model: GeminiConfig.modelName,
        apiKey: GeminiConfig.apiKey,
      );

      // Don't call _initializeChat here, we'll do it lazily when needed
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
      // Initialize chat session if it doesn't exist
      if (_chatSession == null) {
        await _initializeChat();
      }

      // Ensure _chatSession is not null before using it
      if (_chatSession == null) {
        throw Exception('Failed to initialize chat session');
      }

      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );

      // Handle null response safely
      final responseText =
          response.text ?? 'Sorry, I couldn\'t generate a response.';

      return ChatbotMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return ChatbotMessage(
        text:
            'Sorry, I encountered an error. Please try again later. Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}
