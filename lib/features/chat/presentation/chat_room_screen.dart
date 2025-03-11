import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/home/presentation/user_profile_screen.dart';

import '../data/chat_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
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
      final userDetails =
          await chatService.getUserDetailsByEmail(otherUserEmail);

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
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: _buildAppBar(isDarkMode),
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) => _buildMessageList(
                    messages.cast<Map<String, dynamic>>(), isDarkMode),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            _buildMessageInput(isDarkMode),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isDarkMode) {
    // Use _otherUserDetails if available, otherwise fallback to widget.otherUser
    final otherUser =
        _otherUserDetails ?? widget.otherUser ?? <String, dynamic>{};
    final profileImageUrl = otherUser['profile_image_url'] ?? '';
    final userName = otherUser['full_name'] ??
        otherUser['name'] ??
        otherUser['email'] ??
        'Chat';
    final userEmail = otherUser['email'] ?? otherUser['user_email'] ?? '';

    return AppBar(
      backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
      elevation: 2,
      title: GestureDetector(
        onTap: userEmail.isNotEmpty
            ? () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                              userEmail: userEmail,
                            )));
              }
            : null,
        child: Row(
          children: [
            GestureDetector(
              onTap: userEmail.isNotEmpty
                  ? () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                    userEmail: userEmail,
                                  )));
                    }
                  : null,
              child: profileImageUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          CachedNetworkImageProvider(profileImageUrl),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(
      List<Map<String, dynamic>> messages, bool isDarkMode) {
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

        return _buildMessageBubble(message, isMe, isDarkMode);
      },
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isMe, bool isDarkMode) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? (isDarkMode ? Colors.indigo[700] : AppColors.primaryColor)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
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
                color: isMe
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(DateTime.parse(message['timestamp'])),
              style: TextStyle(
                color: isMe
                    ? Colors.white70
                    : (isDarkMode ? Colors.grey[400] : Colors.black54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor:
                isDarkMode ? Colors.indigo[700] : AppColors.primaryColor,
            radius: 24,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
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
        widget.chatRoomId, _currentUserEmail, message);

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
