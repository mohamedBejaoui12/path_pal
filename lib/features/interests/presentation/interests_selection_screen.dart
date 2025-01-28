import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving interests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(interestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Interests'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select up to 4 interests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: interestsAsync.when(
              data: (interests) => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: interests.length,
                itemBuilder: (context, index) {
                  final interest = interests[index];
                  final isSelected = _selectedInterestIds.contains(interest.id);

                  return GestureDetector(
                    onTap: () => _toggleInterest(interest),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            interest.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            interest.name,
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedInterestIds.length >= 1 && _selectedInterestIds.length <= 4 
                ? _saveInterests 
                : null,
              child: Text('Save Interests (${_selectedInterestIds.length}/4)'),
            ),
          ),
        ],
      ),
    );
  }
}