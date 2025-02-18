import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pfe1/features/business/presentation/update_business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/create_business_post_screen.dart';

import '../data/business_profile_provider.dart';
import '../../../shared/theme/app_colors.dart';

class BusinessProfileScreen extends ConsumerWidget {
  final int businessId;

  const BusinessProfileScreen({
    Key? key, 
    required this.businessId
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessDetailsAsync = ref.watch(businessDetailsProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
         IconButton(
  icon: const Icon(Icons.post_add),
  tooltip: 'Create Business Post',
  onPressed: () async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateBusinessPostScreen(businessId: businessId),
      ),
    );

    // If post was created successfully, you might want to refresh something
    if (result == true) {
      // Optionally refresh the business details or posts
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business post created successfully!')),
      );
    }
  },
),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UpdateBusinessProfileScreen(businessId: businessId),
                ),
              );

              // If update was successful, refresh the business details
              if (result == true) {
                ref.read(businessDetailsProvider(businessId).notifier)
                  .refreshBusinessDetails();
              }
            },
          ),
        ],
      ),
      body: businessDetailsAsync.when(
        data: (business) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Profile Image
              business?.imageUrl != null
                ? Image.network(
                    business!.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 250,
                        color: AppColors.primaryColor,
                        child: const Icon(
                          Icons.business, 
                          size: 100, 
                          color: Colors.white
                        ),
                      ),
                  )
                : Container(
                    height: 250,
                    color: AppColors.primaryColor,
                    child: const Icon(
                      Icons.business, 
                      size: 100, 
                      color: Colors.white
                    ),
                  ),

              // Business Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business?.businessName ?? 'Business Name',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: business?.email ?? 'N/A',
                    ),
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: '${business?.latitude}, ${business?.longitude}',
                    ),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Created At',
                      value: business?.createdAt?.toString() ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}