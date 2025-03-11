import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/presentation/user_business_profile_screen.dart';
import 'package:pfe1/features/home/presentation/user_profile_screen.dart';
import 'package:pfe1/features/search/data/search_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Set focus to search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    ref.read(searchResultsProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users or businesses...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchResultsProvider.notifier).clearResults();
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
      ),
      body: searchResults.when(
        data: (data) {
          final users = data['users'] ?? [];
          final businesses = data['businesses'] ?? [];

          if (currentQuery.isEmpty) {
            return const Center(
              child: Text('Type to search for users or businesses'),
            );
          }

          if (users.isEmpty && businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "$currentQuery"',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              if (users.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...users.map((user) => _buildUserListItem(context, user, isDarkMode)),
              ],
              if (businesses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Businesses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...businesses.map((business) => _buildBusinessListItem(context, business, isDarkMode)),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, Map<String, dynamic> user, bool isDarkMode) {
    final name = '${user['name'] ?? ''} ${user['family_name'] ?? ''}';
    final email = user['email'] ?? 'No email';
    final profileImageUrl = user['profile_image_url'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
        child: profileImageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        name.trim().isNotEmpty ? name : 'Unknown User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userEmail: email,
              isOtherUserProfile: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessListItem(BuildContext context, Map<String, dynamic> business, bool isDarkMode) {
    final name = business['business_name'] ?? 'Unknown Business';
    final email = business['email'] ?? 'No email';
    final imageUrl = business['image_url'];
    final id = business['id'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null ? const Icon(Icons.business) : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserBusinessProfileScreen(
              businessId: id,
            ),
          ),
        );
      },
    );
  }
}