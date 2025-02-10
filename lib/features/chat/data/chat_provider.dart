import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_message_model.dart';
import '../domain/chat_room_model.dart';
import './chat_service.dart';
import '../../authentication/providers/auth_provider.dart';

// Supabase Client Provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatService(supabase);
});

// Current Chat Room Provider
final currentChatRoomProvider = StateNotifierProvider<CurrentChatRoomNotifier, ChatRoom?>((ref) {
  return CurrentChatRoomNotifier();
});

// Chat Messages Provider
final chatMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatRoomId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchChatMessages(chatRoomId).map((messages) => 
    messages.map((message) => {
      'id': message.id,
      'chat_room_id': message.chatRoomId,
      'sender_email': message.senderEmail,
      'message': message.message,
      'timestamp': message.timestamp.toIso8601String(),
    }).toList()
  );
});

// User Chat Rooms Provider with detailed user information
final userChatRoomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final chatService = ref.watch(chatServiceProvider);
  
  if (authState.user?.email == null) {
    return [];
  }
  
  try {
    return await chatService.getUserChatRoomsWithDetails(authState.user!.email!);
  } catch (e) {
    debugPrint('Error fetching user chat rooms: $e');
    return [];
  }
});

// User Search Provider
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  final authState = ref.watch(authProvider);
  final chatService = ref.watch(chatServiceProvider);
  return UserSearchNotifier(chatService, authState.user?.email ?? '');
});

// State class for user search
class UserSearchState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;

  UserSearchState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserSearchState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserSearchState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Current Chat Room Notifier
class CurrentChatRoomNotifier extends StateNotifier<ChatRoom?> {
  CurrentChatRoomNotifier() : super(null);

  void setChatRoom(ChatRoom chatRoom) {
    state = chatRoom;
  }

  void clearChatRoom() {
    state = null;
  }
}

// User Search Notifier with improved state management
class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final ChatService _chatService;
  final String? _currentUserEmail;

  UserSearchNotifier(this._chatService, this._currentUserEmail) 
    : super(UserSearchState());

  void updateQuery(String query) {
    if (query.isEmpty) {
      state = UserSearchState();
      return;
    }

    // Trigger search immediately when query changes
    searchUsers(query);
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = UserSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final users = await _chatService.searchUsers(query, _currentUserEmail!);
      
      state = UserSearchState(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      state = UserSearchState(
        users: [],
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error searching users: $e');
    }
  }

  // Method to clear search results
  void clearSearch() {
    state = UserSearchState();
  }
}