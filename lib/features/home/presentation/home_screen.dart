import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/business/data/business_profile_provider.dart';
import 'package:pfe1/features/chat/data/chat_service.dart';
import 'package:pfe1/features/chat/presentation/notification_screen.dart';
import 'package:pfe1/features/home/presentation/business_posts_widget.dart';
import 'package:pfe1/features/home/presentation/profile_widget.dart';
import 'package:pfe1/features/search/presentation/search_screen.dart';
import 'package:pfe1/features/todos/presentation/todos_screen.dart';
import 'package:pfe1/features/map/presentation/map_screen.dart';
import 'package:pfe1/features/vocabulary/presentation/vocabulary_list_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:pfe1/features/home/presentation/post_list_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../features/authentication/data/user_details_provider.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../data/post_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Bottom navigation: 0 = Home (with posts tabs), 1 = Todo, 2 = Map, 3 = Profile.
  int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads user details if an email is available.
  void _loadUserData() {
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user?.email != null) {
        ref
            .read(userDetailsProvider.notifier)
            .fetchUserDetails(authState.user!.email);
      }
    });
  }

  /// Refresh posts by calling the provider method.
  Future<void> _refreshPosts() async {
    try {
      await ref.read(postListProvider.notifier).fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Wraps the user posts list in a RefreshIndicator.
  Widget _buildRefreshablePosts() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshPosts,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.0,
      child: PostListWidget(),
    );
  }

  /// Builds an AppBar.
  /// When _currentIndex == 0, it adds a TabBar (for Home) to the bottom.
  PreferredSizeWidget _buildAppBar() {
    final isDarkMode = ref.watch(themeProvider);
    final userEmail = ref.watch(authProvider).user?.email;
    final chatService = ChatService(supabase.Supabase.instance.client);

    if (_currentIndex == 0) {
      return AppBar(
        title: const Text(
          'PathPal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'User Posts'),
            Tab(text: 'Business Posts'),
          ],
        ),
        actions: [
          // Add search icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          // Notification icon with badge
          userEmail != null
              ? StreamBuilder<int>(
                  stream: chatService.watchUnreadNotificationCount(userEmail),
                  builder: (context, snapshot) {
                    final hasUnread = snapshot.hasData && snapshot.data! > 0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (hasUnread)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () {
              context.push('/chat/list');
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Text(
          'PathPal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          // Notification icon with badge
          userEmail != null
              ? StreamBuilder<int>(
                  stream: chatService.watchUnreadNotificationCount(userEmail),
                  builder: (context, snapshot) {
                    final hasUnread = snapshot.hasData && snapshot.data! > 0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (hasUnread)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () {
              context.push('/chat/list');
            },
          ),
        ],
      );
    }
  }

  /// Builds the body of the Scaffold.
  /// For _currentIndex == 0, returns a TabBarView wrapped in a DefaultTabController.
  Widget _buildBody() {
    if (_currentIndex == 0) {
      return TabBarView(
        children: [
          _buildRefreshablePosts(), // User posts with refresh capability.
          BusinessPostsWidget(), // Business posts.
        ],
      );
    } else if (_currentIndex == 1) {
      return TodosScreen();
    } else if (_currentIndex == 2) {
      // Replace the placeholder with the actual MapScreen
      return const MapScreen();
    } else if (_currentIndex == 3) {
      final authState = ref.watch(authProvider);
      final currentUserEmail = authState.user?.email ?? '';
      return ProfileWidget(userEmail: currentUserEmail);
    }
    return Container();
  }

  /// Builds the bottom navigation bar.
  Widget _buildBottomNavigationBar() {
    return SalomonBottomBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        /// Home
        SalomonBottomBarItem(
          icon: const Icon(Icons.home),
          title: const Text("Home"),
          selectedColor: AppColors.primaryColor,
        ),

        /// Todo
        SalomonBottomBarItem(
          icon: const Icon(Icons.checklist),
          title: const Text("Todo"),
          selectedColor: Colors.blue,
        ),

        /// Map
        SalomonBottomBarItem(
          icon: const Icon(Icons.map),
          title: const Text("Map"),
          selectedColor: Colors.green,
        ),

        /// Profile
        SalomonBottomBarItem(
          icon: const Icon(Icons.person),
          title: const Text("Profile"),
          selectedColor: Colors.pink,
        ),
      ],
    );
  }

  /// Builds the drawer with user information and menu options.
  Widget _buildDrawer(BuildContext context, AuthState authState,
      dynamic userDetails, bool isDarkMode) {
    // Combine first and last names.
    String fullName = '';
    if (userDetails != null) {
      fullName = [
        userDetails.name,
        userDetails.familyName,
      ].where((name) => name.isNotEmpty).join(' ');
    }
    // Rest of the method remains unchanged
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.white,
                    backgroundImage: userDetails?.profileImageUrl != null
                        ? NetworkImage(userDetails.profileImageUrl!)
                        : null,
                    child: userDetails?.profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 34,
                            color: AppColors.primaryColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 18),
                // User info: Name and Email.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authState.user?.email ?? 'No email',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Drawer menu options:
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Update Profile'),
            onTap: () => context.push('/update-profile'),
          ),
          // Add Vocabulary feature link here
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Vocabulary'),
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularyListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Add settings navigation here.
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Manage Business'),
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToBusiness(context);
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  /// Handles navigation for business management.
  void _navigateToBusiness(BuildContext context) async {
    final businessProvider = ref.read(businessProfileProvider);
    final authState = ref.read(authProvider);

    final userEmail = authState.user?.email;
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    try {
      final userBusiness =
          await businessProvider.getFirstUserBusiness(userEmail);
      if (userBusiness != null) {
        context.push('/business-profile/${userBusiness.id}');
      } else {
        final canCreateBusiness =
            await businessProvider.canCreateBusiness(userEmail);
        if (canCreateBusiness) {
          context.push('/add-business');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only create one business'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing business: $e')),
      );
    }
  }

  /// Builds the overall theme.
  ThemeData _buildTheme(bool isDarkMode) {
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final userDetails = ref.watch(userDetailsProvider).userDetails;

    // Build the Scaffold.
    Widget scaffold = Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context, authState, userDetails, isDarkMode),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/create-post'),
              child: const Icon(Icons.add),
            )
          : null,
    );

    // If on the Home tab, wrap the scaffold in a DefaultTabController.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDarkMode),
      home: _currentIndex == 0
          ? DefaultTabController(length: 2, child: scaffold)
          : scaffold,
    );
  }
}
