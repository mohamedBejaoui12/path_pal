import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/business_rate_provider.dart';
import '../data/business_profile_provider.dart';
import '../domain/business_rate_model.dart';
import 'rate_business_bottom_sheet.dart';

class BusinessRatingsPage extends ConsumerWidget {
  final int businessId;

  const BusinessRatingsPage({Key? key, required this.businessId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessDetailsAsync = ref.watch(businessDetailsProvider(businessId));
    final ratingsAsync = ref.watch(businessRatingsProvider(businessId));
    final averageRatingAsync =
        ref.watch(businessAverageRatingProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          businessDetailsAsync.value?.businessName ?? 'Business Ratings',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          // Average Rating Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Average Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  averageRatingAsync.when(
                    data: (rating) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating.floor()
                                  ? Icons.star
                                  : (index < rating.ceil() &&
                                          index >= rating.floor())
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${rating.toStringAsFixed(1)} / 5.0',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Unable to load rating'),
                  ),
                ],
              ),
            ),
          ),

          // Rate Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.star, color: Colors.white),
                label: const Text(
                  'Rate This Business',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _showRateBusinessBottomSheet(context, ref, businessId,
                      businessDetailsAsync.value?.businessName ?? 'Business');
                },
              ),
            ),
          ),

          // All Ratings List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Ratings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ratingsAsync.when(
                      data: (ratings) {
                        if (ratings.isEmpty) {
                          return const Center(
                            child:
                                Text('No ratings yet. Be the first to rate!'),
                          );
                        }

                        return ListView.builder(
                          itemCount: ratings.length,
                          itemBuilder: (context, index) {
                            final rating = ratings[index];
                            return _buildRatingCard(context, rating);
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('Error loading ratings: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, BusinessRateModel rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Replace CircleAvatar with proper user profile image handling
                rating.userProfileImage != null &&
                        rating.userProfileImage!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(rating.userProfileImage!),
                        radius: 20,
                        onBackgroundImageError: (_, __) {
                          // Fallback to initial if image fails to load
                          return;
                        },
                      )
                    : CircleAvatar(
                        backgroundColor:
                            AppColors.primaryColor.withOpacity(0.2),
                        radius: 20,
                        child: Text(
                          rating.userEmail.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userEmail.split('@').first,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(rating.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(rating.comment!),
              ),
          ],
        ),
      ),
    );
  }

  // Update this method to handle nullable DateTime
  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Unknown date';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRateBusinessBottomSheet(BuildContext context, WidgetRef ref,
      int businessId, String businessName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RateBusinessBottomSheet(
        businessId: businessId,
        businessName: businessName,
      ),
    ).then((result) {
      if (result == true) {
        // Refresh ratings if a new rating was submitted
        ref.invalidate(businessRatingsProvider(businessId));
        ref.invalidate(businessAverageRatingProvider(businessId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
      }
    });
  }
}
