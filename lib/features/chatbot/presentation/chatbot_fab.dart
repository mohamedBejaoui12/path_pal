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
          child: ClipOval(
            child: Image.asset(
              'assets/images/amSloma.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
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
