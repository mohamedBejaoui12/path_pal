import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/chat_provider.dart';

import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listener to trigger search as user types
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Use a debounce to avoid too many API calls
    ref.read(userSearchProvider.notifier).updateQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
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
          authState.user!.email!, user['email']);

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
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(Icons.search,
                    color:
                        isDarkMode ? Colors.white70 : AppColors.primaryColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color:
                        isDarkMode ? Colors.grey[700]! : AppColors.primaryColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.white : AppColors.primaryColor,
                      width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: searchState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color:
                          isDarkMode ? Colors.white70 : AppColors.primaryColor,
                    ),
                  )
                : searchState.users.isEmpty
                    ? _buildNoResultsWidget(isDarkMode)
                    : _buildUserList(searchState.users, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 100,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isDarkMode) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
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
                leading: _buildUserAvatar(user),
                title: Text(
                  '${user['full_name'] ?? user['email']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  user['email'],
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                trailing: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(isDarkMode
                            ? Colors.white70
                            : AppColors.primaryColor),
                      )
                    : Icon(
                        Icons.chat_bubble_outline,
                        color:
                            isDarkMode ? Colors.white : AppColors.primaryColor,
                      ),
                onTap: _isLoading ? null : () => _initiateChat(user),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final profileImageUrl = user['profile_image_url'] ?? '';

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
}
