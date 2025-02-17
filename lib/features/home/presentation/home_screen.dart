import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/business/data/business_profile_provider.dart';
import 'package:pfe1/features/business/presentation/add_business_screen.dart';
import 'package:pfe1/features/home/presentation/profile_widget.dart';
import 'package:pfe1/features/todos/presentation/todos_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../../features/authentication/data/user_details_provider.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../../../features/home/presentation/post_list_widget.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../data/post_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = 
    GlobalKey<RefreshIndicatorState>();

  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user?.email != null) {
        ref.read(userDetailsProvider.notifier).fetchUserDetails(authState.user!.email);
      }
    });
  }

  // Screens for bottom navigation
  late List<Widget> _screens;

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Get the current user's email
  final authState = ref.read(authProvider);
  final currentUserEmail = authState.user?.email;

  _screens = [
    _buildRefreshablePosts(),
    TodosScreen(),  
    Center(child: Text('Map Screen (Coming Soon)', style: TextStyle(fontSize: 18))),
    // Pass the current user's email to ProfileWidget
    ProfileWidget(userEmail: currentUserEmail ?? ''),
  ];
}

  // Refreshable Posts Widget
  Widget _buildRefreshablePosts() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshPosts,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.0,
      child: const PostListWidget(),
    );
  }

  // Refresh Posts Method
  Future<void> _refreshPosts() async {
    try {
      // Fetch posts using the PostListNotifier
      await ref.read(postListProvider.notifier).fetchPosts();
    } catch (e) {
      // Show error snackbar if refresh fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final userDetails = ref.watch(userDetailsProvider).userDetails;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDarkMode),
      home: Scaffold(
        appBar: _buildAppBar(context, isDarkMode),
        drawer: _buildDrawer(context, authState, userDetails, isDarkMode),
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: () => context.push('/create-post'),
              child: const Icon(Icons.add),
            )
          : null,
      ),
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
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
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          onPressed: () {
            // Navigate to chat list screen
            context.push('/chat/list');
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return SalomonBottomBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
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

  Widget _buildDrawer(BuildContext context, AuthState authState, dynamic userDetails, bool isDarkMode) {
    // Combine name and family name
    String fullName = '';
    if (userDetails != null) {
      fullName = [
        userDetails.name,
        userDetails.familyName
      ].where((name) => name.isNotEmpty).join(' ');
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
            ),
            // Increased horizontal and vertical padding for more space
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture with increased size
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 34, // Increased radius from 32 to 36
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
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
                
                // User Info with updated spacing and text sizes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'User',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.white,
                          fontSize: 18, // Increased font size
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // More space between name and email
                      Text(
                        authState.user?.email ?? 'No email',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.white70,
                          fontSize: 14, // Increased font size for better readability
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
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Update Profile '),
            onTap: () => context.push('/update-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Manage Business'),
            onTap: () {
              // Ensure we're not on the last route
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              
              // Use a post-frame callback to navigate after current frame
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

  void _navigateToBusiness(BuildContext context) async {
    final businessProvider = ref.read(businessProfileProvider);
    final authState = ref.read(authProvider);
    
    // Use null-aware operator to handle potential null email
    final userEmail = authState.user?.email;
    
    if (userEmail == null) {
      // User not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    try {
      // Get the user's first business (if any)
      final userBusiness = await businessProvider.getFirstUserBusiness(userEmail);
      
      if (userBusiness != null) {
        // User has a business, navigate to business profile
        context.push('/business-profile/${userBusiness.id}');
      } else {
        // Check if user can create a business
        final canCreateBusiness = await businessProvider.canCreateBusiness(userEmail);
        
        if (canCreateBusiness) {
          // No business exists, navigate to add business screen
          context.push('/add-business');
        } else {
          // User has reached maximum business limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only create one business'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Error checking business status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing business: $e')),
      );
    }
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}