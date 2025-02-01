import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/interest_service.dart';
import '../domain/interest_model.dart';

final interestsProvider = FutureProvider<List<InterestModel>>((ref) {
  final interestService = InterestService();
  return interestService.fetchAllInterests();
});

class InterestsSelectionScreen extends ConsumerStatefulWidget {
  final int userId;

  const InterestsSelectionScreen({
    Key? key, 
    required this.userId
  }) : super(key: key);

  @override
  _InterestsSelectionScreenState createState() => _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends ConsumerState<InterestsSelectionScreen> {
  final Set<int> _selectedInterestIds = {};
  final InterestService _interestService = InterestService();

  void _toggleInterest(InterestModel interest) {
    setState(() {
      if (_selectedInterestIds.contains(interest.id)) {
        _selectedInterestIds.remove(interest.id);
      } else if (_selectedInterestIds.length < 4) {
        _selectedInterestIds.add(interest.id!);
      }
    });
  }

  void _saveInterests() async {
    try {
      await _interestService.saveUserInterests(
        userId: widget.userId, 
        interestIds: _selectedInterestIds.toList()
      );

      // Navigate to next screen or show success message
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving interests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader(Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Column(
        children: [
          Text(
            'Ahlan wa Sahlan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
              shadows: [
                const Shadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select Your Interests',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 2,
            width: 100,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(interestsProvider);

    return LoadingOverlay(
      isLoading: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColor, AppColors.backgroundColor],
              stops: const [0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(AppColors.primaryColor, AppColors.secondaryColor),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Select up to 4 interests',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: interestsAsync.when(
                          data: (interests) => GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.2, // Adjusted to make cards smaller
                            ),
                            itemCount: interests.length,
                            itemBuilder: (context, index) {
                              final interest = interests[index];
                              final isSelected = _selectedInterestIds.contains(interest.id);

                              return GestureDetector(
                                onTap: () => _toggleInterest(interest),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(15), // Increased border radius
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column( // Changed back to Column
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          interest.emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          interest.name,
                                          style: TextStyle(
                                            color: isSelected ? AppColors.primaryColor : Colors.black,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(
                            child: Text('Error loading interests: $error'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedInterestIds.length >= 1 && _selectedInterestIds.length <= 4 
                            ? _saveInterests 
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            shadowColor: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          child: Text(
                            'Save Interests (${_selectedInterestIds.length}/4)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}