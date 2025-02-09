import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/chat_message_model.dart';
import '../domain/chat_room_model.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // Create or get existing chat room between two users
  Future<ChatRoom> createOrGetChatRoom(String currentUserEmail, String otherUserEmail) async {
    try {
      // Check if chat room already exists
      final existingRoomResponse = await _supabase
          .from('chat_rooms')
          .select()
          .or('user1_email.eq.$currentUserEmail,user1_email.eq.$otherUserEmail')
          .or('user2_email.eq.$currentUserEmail,user2_email.eq.$otherUserEmail')
          .maybeSingle();

      if (existingRoomResponse != null) {
        return ChatRoom(
          id: existingRoomResponse['id'],
          user1Email: existingRoomResponse['user1_email'],
          user2Email: existingRoomResponse['user2_email'],
          lastMessage: existingRoomResponse['last_message'],
          lastMessageTimestamp: existingRoomResponse['last_message_timestamp'] != null 
            ? DateTime.parse(existingRoomResponse['last_message_timestamp']) 
            : null,
        );
      }

      // Create new chat room
      final newRoom = await _supabase
          .from('chat_rooms')
          .insert({
            'user1_email': currentUserEmail,
            'user2_email': otherUserEmail,
          })
          .select()
          .single();

      return ChatRoom(
        id: newRoom['id'],
        user1Email: newRoom['user1_email'],
        user2Email: newRoom['user2_email'],
        lastMessage: null,
        lastMessageTimestamp: null,
      );
    } catch (e) {
      print('Error creating/getting chat room: $e');
      rethrow;
    }
  }

  // Send a message in a chat room
  Future<ChatMessage> sendMessage({
    required String chatRoomId, 
    required String senderEmail, 
    required String message
  }) async {
    try {
      final timestamp = DateTime.now();

      // Insert message
      final messageData = await _supabase
          .from('chat_messages')
          .insert({
            'chat_room_id': chatRoomId,
            'sender_email': senderEmail,
            'message': message,
            'timestamp': timestamp.toIso8601String(),
          })
          .select()
          .single();

      // Update last message in chat room
      await _supabase
          .from('chat_rooms')
          .update({
            'last_message': message,
            'last_message_timestamp': timestamp.toIso8601String(),
          })
          .eq('id', chatRoomId);

      // Ensure the returned data matches the ChatMessage model
      return ChatMessage(
        id: messageData['id'],
        chatRoomId: messageData['chat_room_id'],
        senderEmail: messageData['sender_email'],
        message: messageData['message'],
        timestamp: timestamp,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a specific chat room
  Stream<List<ChatMessage>> watchChatMessages(String chatRoomId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('timestamp', ascending: true)
        .map((data) {
          return data.map<ChatMessage>((json) {
            return ChatMessage(
              id: json['id'],
              chatRoomId: json['chat_room_id'],
              senderEmail: json['sender_email'],
              message: json['message'],
              timestamp: DateTime.parse(json['timestamp']),
            );
          }).toList();
        });
  }

  // Get chat rooms for a user
  Future<List<ChatRoom>> getUserChatRooms(String userEmail) async {
    try {
      final rooms = await _supabase
          .from('chat_rooms')
          .select('*, chat_messages(last_message, timestamp)')
          .or('user1_email.eq.$userEmail,user2_email.eq.$userEmail')
          .order('last_message_timestamp', ascending: false);

      return rooms.map<ChatRoom>((roomJson) {
        // Determine the other user's email
        final otherUserEmail = roomJson['user1_email'] == userEmail 
          ? roomJson['user2_email'] 
          : roomJson['user1_email'];

        return ChatRoom(
          id: roomJson['id'],
          user1Email: roomJson['user1_email'],
          user2Email: roomJson['user2_email'],
          lastMessage: roomJson['last_message'],
          lastMessageTimestamp: roomJson['last_message_timestamp'] != null
            ? DateTime.parse(roomJson['last_message_timestamp'])
            : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching user chat rooms: $e');
      return [];
    }
  }

  // Fetch user details for a specific email
  Future<Map<String, dynamic>?> getUserDetailsByEmail(String email) async {
    try {
      final response = await _supabase
          .from('user')
          .select('name, family_name, email, description')
          .eq('email', email)
          .single();
      
      return {
        'full_name': '${response['name']} ${response['family_name']}',
        'email': response['email'],
        'description': response['description'] ?? '',
      };
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Get detailed chat rooms for a user with user details
  Future<List<Map<String, dynamic>>> getUserChatRoomsWithDetails(String userEmail) async {
    try {
      // First, get the chat rooms
      final rooms = await _supabase
          .from('chat_rooms')
          .select()
          .or('user1_email.eq.$userEmail,user2_email.eq.$userEmail')
          .order('last_message_timestamp', ascending: false);

      // Fetch details for each chat room
      final detailedRooms = <Map<String, dynamic>>[];
      for (var room in rooms) {
        try {
          // Determine the other user's email
          final otherUserEmail = room['user1_email'] == userEmail 
            ? room['user2_email'] 
            : room['user1_email'];

          // Skip if no other user email
          if (otherUserEmail == null) continue;

          // Fetch other user's details
          final otherUserDetails = await getUserDetailsByEmail(otherUserEmail);

          if (otherUserDetails != null) {
            detailedRooms.add({
              'chat_room_id': room['id'],
              'last_message': room['last_message'] ?? '',
              'last_message_timestamp': room['last_message_timestamp'] != null
                ? DateTime.parse(room['last_message_timestamp'])
                : null,
              'other_user': otherUserDetails,
              'user1_email': room['user1_email'],
              'user2_email': room['user2_email'],
            });
          }
        } catch (userDetailError) {
          print('Error processing user details for room: $userDetailError');
        }
      }

      return detailedRooms;
    } catch (e) {
      print('Error fetching detailed chat rooms: $e');
      return [];
    }
  }

  // Search users to start a chat
  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserEmail) async {
    try {
      // If query is empty, return empty list
      if (query.trim().isEmpty) return [];

      final users = await _supabase
          .from('user')
          .select('email, name, family_name, description')
          .or(
            'email.ilike.%${query.trim()}%, name.ilike.%${query.trim()}%, family_name.ilike.%${query.trim()}%'
          )
          .neq('email', currentUserEmail)
          .limit(10);

      // Transform results to match expected format
      return users.map((user) => {
        'email': user['email'],
        'full_name': '${user['name']} ${user['family_name']}',
        'profile_picture': null, // Add profile picture if available
        'description': user['description']
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}