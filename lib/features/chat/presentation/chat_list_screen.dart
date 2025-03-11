import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/chat_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final chatRoomsAsync = ref.watch(userChatRoomsProvider);
    final authState = ref.watch(authProvider);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            )),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_rounded, color: Colors.white),
            onPressed: () {
              // Navigate to user search screen to start a new chat
              context.push('/chat/search');
            },
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }
          return _buildChatList(chatRooms, isDarkMode);
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
          ),
        ),
        error: (error, stack) => _buildErrorState(error, isDarkMode),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Navigate to user search screen
              context.push('/chat/search');
            },
            child: Text('Start a Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? Colors.grey[700] : AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> chatRooms, bool isDarkMode) {
    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final otherUser = chatRoom['other_user'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 4,
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          Colors.grey[850]!,
                          Colors.grey[800]!,
                        ]
                      : [
                          AppColors.primaryColor.withOpacity(0.1),
                          AppColors.primaryColor.withOpacity(0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: _buildUserAvatar(otherUser),
                title: Text(
                  otherUser['full_name'] ?? otherUser['email'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser['description'] ?? 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      chatRoom['last_message'] ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.black54,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chatRoom['last_message_timestamp'] != null)
                      Text(
                        DateFormat('HH:mm\ndd/MM')
                            .format(chatRoom['last_message_timestamp']),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  // Navigate to chat room
                  context
                      .push('/chat/room/${chatRoom['chat_room_id']}', extra: {
                    'otherUser': otherUser,
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> otherUser) {
    final profileImageUrl = otherUser['profile_image_url'] ?? '';

    return profileImageUrl.isNotEmpty
        ? CircleAvatar(
            radius: 30,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl),
          )
        : CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: AppColors.primaryColor,
              size: 30,
            ),
          );
  }

  Widget _buildErrorState(Object error, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 100,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            error.toString(),
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh the provider
              ref.invalidate(userChatRoomsProvider);
            },
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? Colors.grey[700] : AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
