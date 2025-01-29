import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                authState.user?.email ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                authState.user?.email ?? 'No email',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (authState.user?.email ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 40.0,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Details'),
              onTap: () {
                context.push('/user-profile');
                Navigator.of(context).pop(); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Implement settings page
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 100,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${authState.user?.email ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}