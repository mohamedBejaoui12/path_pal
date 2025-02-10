import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/chat_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/chat_service.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic>? otherUser;

  const ChatRoomScreen({
    Key? key, 
    required this.chatRoomId, 
    this.otherUser,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late String _currentUserEmail;
  Map<String, dynamic>? _otherUserDetails;

  @override
  void initState() {
    super.initState();
    _currentUserEmail = ref.read(authProvider).user?.email ?? '';
    
    // Fetch user details if not provided
    if (widget.otherUser == null) {
      _fetchOtherUserDetails();
    }
  }

  Future<void> _fetchOtherUserDetails() async {
    try {
      // Determine the other user's email from the chat room
      final chatService = ref.read(chatServiceProvider);
      final chatRoomsAsync = await ref.read(userChatRoomsProvider.future);
      
      // Find the chat room or return if not found
      final chatRoom = chatRoomsAsync.firstWhere(
        (room) => room['chat_room_id'] == widget.chatRoomId,
        orElse: () => <String, dynamic>{},
      );

      // Check if chatRoom is empty
      if (chatRoom.isEmpty) return;

      final otherUserEmail = chatRoom['user1_email'] == _currentUserEmail 
        ? chatRoom['user2_email'] 
        : chatRoom['user1_email'];

      // Skip if no other user email
      if (otherUserEmail == null) return;

      // Fetch other user's details
      final userDetails = await chatService.getUserDetailsByEmail(otherUserEmail);
      
      if (userDetails != null) {
        setState(() {
          _otherUserDetails = userDetails;
        });
      }
    } catch (e) {
      print('Error fetching other user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatRoomId));

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessageList(messages.cast<Map<String, dynamic>>()),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    // Use _otherUserDetails if available, otherwise fallback to widget.otherUser
    final otherUser = _otherUserDetails ?? widget.otherUser ?? <String, dynamic>{};
    final profileImageUrl = otherUser['profile_image_url'] ?? '';
    final userName = otherUser['full_name'] ?? otherUser['email'] ?? 'Chat';

    return AppBar(
      backgroundColor: AppColors.primaryColor,
      title: Row(
        children: [
          profileImageUrl.isNotEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(profileImageUrl),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(Icons.person, color: Colors.white),
              ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message['sender_email'] == _currentUserEmail;

        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe 
            ? AppColors.primaryColor.withOpacity(0.8) 
            : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(DateTime.parse(message['timestamp'])),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatService = ref.read(chatServiceProvider);
    final sentMessage = await chatService.sendMessage(
      widget.chatRoomId, 
      _currentUserEmail, 
      message
    );

    if (sentMessage != null) {
      _messageController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}