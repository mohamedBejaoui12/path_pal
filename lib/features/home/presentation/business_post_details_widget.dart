import 'package:flutter/material.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart'; // Adjust the import as necessary

class BusinessPostDetailWidget extends StatelessWidget {
  final int postId; // Ensure this is non-nullable

  const BusinessPostDetailWidget({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement your logic to fetch and display the post details using postId
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Center(
        child: Text('Details for post ID: $postId'), // Replace with actual post details
      ),
    );
  }
}