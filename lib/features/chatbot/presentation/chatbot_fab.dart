import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../shared/theme/app_colors.dart';
import 'chatbot_screen.dart';

class ChatbotFAB extends StatelessWidget {
  const ChatbotFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FloatingActionButton(
          heroTag: 'chatbotFAB',
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChatbotScreen(),
              ),
            );
          },
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        
        // Beta badge
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        // Animation overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_kk62um5v.json',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}