import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/chat_provider.dart';
import '../data/chat_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initiateChat(Map<String, dynamic> user) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final chatService = ref.read(chatServiceProvider);

      // Create or get existing chat room
      final chatRoom = await chatService.createOrGetChatRoom(
        authState.user!.email!, 
        user['email']
      );

      // Check if widget is still mounted before navigating
      if (!mounted) return;

      // Navigate to chat room
      context.push('/chat/room/${chatRoom.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(userSearchProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                ref.read(userSearchProvider.notifier).searchUsers(value);
              },
            ),
          ),
          if (searchState.isLoading)
            Center(child: CircularProgressIndicator()),
          
          if (searchState.error != null)
            Center(
              child: Text(
                'Error: ${searchState.error}',
                style: TextStyle(color: Colors.red),
              ),
            ),
          
          Expanded(
            child: searchState.users.isEmpty
                ? Center(
                    child: Text(
                      searchState.isLoading 
                        ? 'Searching...' 
                        : 'Search for users',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchState.users.length,
                    itemBuilder: (context, index) {
                      final user = searchState.users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profile_picture'] != null
                              ? NetworkImage(user['profile_picture'])
                              : null,
                          child: user['profile_picture'] == null 
                              ? Icon(Icons.person) 
                              : null,
                        ),
                        title: Text(user['full_name'] ?? user['email']),
                        subtitle: Text(user['email']),
                        onTap: _isLoading 
                          ? null 
                          : () => _initiateChat(user),
                        trailing: _isLoading 
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor
                              ),
                            )
                          : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}