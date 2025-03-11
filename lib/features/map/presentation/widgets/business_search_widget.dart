import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../business/domain/business_model.dart';

class BusinessSearchWidget extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final Function(String) onSearch;
  final Function(BusinessModel) onBusinessSelected;
  final List<BusinessModel> searchResults;

  const BusinessSearchWidget({
    Key? key,
    required this.searchController,
    required this.isSearching,
    required this.onSearch,
    required this.onBusinessSelected,
    required this.searchResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input field
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search business',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primaryColor),
              suffixIcon: isSearching
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(6),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        onSearch(''); // Clear search results when text is cleared
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onChanged: onSearch, // Real-time search
          ),
        ),

        // Search results
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final business = searchResults[index];
                return ListTile(
                  leading: business.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            business.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.business,
                                  color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.business, color: Colors.grey),
                        ),
                  title: Text(
                    business.businessName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(business.email ?? 'No email'),
                  onTap: () => onBusinessSelected(business),
                );
              },
            ),
          ),
      ],
    );
  }
}
