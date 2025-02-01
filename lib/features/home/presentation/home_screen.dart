import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/authentication/data/user_details_provider.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

// Theme Provider
final themeProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final userDetails = ref.watch(userDetailsProvider).userDetails;

    return MaterialApp(
          debugShowCheckedModeBanner: false, // Add this line
      theme: _buildTheme(isDarkMode),
      home: Scaffold(
        appBar: _buildAppBar(context, isDarkMode),
        drawer: _buildDrawer(context, authState, userDetails, isDarkMode),
        body: const Center(child: Text('Main Content Area')),
      ),
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    return ThemeData(
      scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.primaryColor),
        trackColor: MaterialStateProperty.all(AppColors.primaryColor.withOpacity(0.5)),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      title: Row(
        
        children: [
        
          Text(
            'PathPal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.add_comment_outlined), onPressed: () {}),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AuthState authState, UserDetailsModel? userDetails, bool isDarkMode) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(authState, userDetails, isDarkMode),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  icon: Icons.edit,
                  title: 'Update Profile Data',
                  onTap: () => context.push('/user-profile'),
                ),
                _buildListTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {},
                ),
                _buildDarkModeSwitch(isDarkMode),
                const Divider(),
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  color: Colors.red,
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  UserAccountsDrawerHeader _buildDrawerHeader(AuthState authState, UserDetailsModel? userDetails, bool isDarkMode) {
    return UserAccountsDrawerHeader(
      accountName: const SizedBox.shrink(), // Remove account name
      accountEmail: Text(
        authState.user?.email ?? 'No email',
        style: TextStyle(
          color: isDarkMode ? Colors.white : AppColors.primaryColor,
          fontSize: 16,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        backgroundImage: userDetails?.profileImageUrl != null
            ? NetworkImage(userDetails!.profileImageUrl!)
            : null,
        child: userDetails?.profileImageUrl == null
            ? Icon(Icons.person, color: AppColors.primaryColor)
            : null,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
      ),
    );
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

  Widget _buildDarkModeSwitch(bool isDarkMode) {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      secondary: Icon(
        isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      value: isDarkMode,
      onChanged: (value) => ref.read(themeProvider.notifier).state = value,
    );
  }
}