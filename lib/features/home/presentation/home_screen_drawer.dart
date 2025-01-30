import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/authentication/data/user_details_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

class HomeScreenDrawer extends ConsumerWidget {
  const HomeScreenDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userDetailsState = ref.watch(userDetailsProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
            ),
            accountName: Text(
              userDetailsState.userDetails != null 
                ? '${userDetailsState.userDetails!.name} ${userDetailsState.userDetails!.familyName}' 
                : 'User Name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              authState.user?.email ?? 'user@example.com',
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: userDetailsState.userDetails?.profileImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: userDetailsState.userDetails!.profileImageUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => 
                          CircularProgressIndicator(color: AppColors.primaryColor),
                      errorWidget: (context, url, error) => 
                          Icon(Icons.person, size: 60, color: AppColors.primaryColor),
                    )
                  : Icon(
                      Icons.person, 
                      size: 60, 
                      color: AppColors.primaryColor
                    ),
              ),
            ),
          ),
          
          // Drawer Menu Items
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // TODO: Implement settings page
              Navigator.pop(context);
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // TODO: Implement help page
              Navigator.pop(context);
            },
          ),
          
          const Divider(),
          
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // Logout logic
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // Helper method to build drawer items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: color ?? AppColors.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}