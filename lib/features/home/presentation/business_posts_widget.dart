import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/data/business_post_provider.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/home/presentation/business_post_details_widget.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class BusinessPostsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch all business posts using the provider
    final businessPostsAsync = ref.watch(businessPostsProvider);

    return businessPostsAsync.when(
      data: (posts) {
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Profile Image and Name
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: post.businessProfileImage != null && post.businessProfileImage!.isNotEmpty
                              ? CachedNetworkImageProvider(post.businessProfileImage!)
                              : null,
                          child: post.businessProfileImage == null || post.businessProfileImage!.isEmpty
                              ? const Icon(Icons.business, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Post Image
                    if (post.imageUrl != null) 
                      CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    const SizedBox(height: 8),
                    // Post Title and Description
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(post.description ?? '', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    // Date
                    Text(
                      DateFormat('yyyy-MM-dd').format(post.createdAt ?? DateTime.now()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Likes and Comments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${post.likesCount}'),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.comment, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${post.commentsCount} Comments'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Comment Button
                    ElevatedButton(
                      onPressed: () {
                        if (post.id != null) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => CommentsBottomSheet(postId: post.id!),
                          );
                        }
                      },
                      child: const Text('View Comments'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}