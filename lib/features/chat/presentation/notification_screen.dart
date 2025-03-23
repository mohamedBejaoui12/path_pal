import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/chat/data/chat_service.dart';
import 'package:pfe1/features/chat/presentation/chat_room_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(Supabase.instance.client);
});

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  late Stream<int> _unreadNotificationsStream;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Set up the stream for unread notifications
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail != null) {
      _unreadNotificationsStream = ref.read(chatServiceProvider).watchUnreadNotificationCount(userEmail);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null) {
        final notifications = await ref.read(chatServiceProvider).getUserNotifications(userEmail);
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null) {
        final success = await ref.read(chatServiceProvider).markAllNotificationsAsRead(userEmail);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read')),
          );
          _loadNotifications();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final success = await ref.read(chatServiceProvider).markNotificationAsRead(notificationId);
      if (success) {
        _loadNotifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  // Add method to delete a single notification
  Future<void> _deleteNotification(String notificationId) async {
    try {
      final success = await ref.read(chatServiceProvider).deleteNotification(notificationId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
        _loadNotifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  // Add method to delete all notifications
  Future<void> _deleteAllNotifications() async {
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null) {
        final success = await ref.read(chatServiceProvider).deleteAllNotifications(userEmail);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications deleted')),
          );
          _loadNotifications();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notifications: $e')),
      );
    }
  }

  void _navigateToChatScreen(String chatRoomId, Map<String, dynamic> sender) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoomId: chatRoomId,
          otherUser: sender,
        ),
      ),
    ).then((_) => _loadNotifications());
  }

  // Add confirmation dialog for deleting all notifications
  Future<void> _showDeleteAllConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notifications'),
          content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllNotifications();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
          // Add delete all button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _notifications.isEmpty ? null : _showDeleteAllConfirmation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final sender = notification['sender'];
                      final isRead = notification['is_read'] as bool;
                      final createdAt = notification['created_at'] as DateTime;
                      final formattedDate = DateFormat.yMMMd().add_jm().format(createdAt);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: sender['profile_image_url'].isNotEmpty
                              ? NetworkImage(sender['profile_image_url'])
                              : null,
                          child: sender['profile_image_url'].isEmpty
                              ? Text(sender['full_name'][0])
                              : null,
                        ),
                        title: Text(
                          sender['full_name'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['message'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Unread indicator
                            if (!isRead)
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNotification(notification['id']),
                            ),
                          ],
                        ),
                        onTap: () {
                          _markAsRead(notification['id']);
                          _navigateToChatScreen(
                            notification['chat_room_id'],
                            sender,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}