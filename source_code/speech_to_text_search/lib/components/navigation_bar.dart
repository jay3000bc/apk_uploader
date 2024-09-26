import 'package:flutter/material.dart';
import 'package:speech_to_text_search/pages/refund.dart';
import 'package:speech_to_text_search/pages/search_app.dart';
import 'package:speech_to_text_search/pages/view_inventory.dart';
import 'package:speech_to_text_search/pages/view_sub_user.dart';

class CustomNavigationBar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const CustomNavigationBar({
    super.key,
    required this.onItemSelected,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 90, // Reduced the height to fit contents better
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFF2CC44),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 5), // Reduced padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: _buildNavItem(
                label: 'Home',
                context: context,
                icon: Icons.home_outlined,
                index: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchApp(),
                    ),
                  );
                },
                isSelected: selectedIndex == 0,
              ),
            ),
            Flexible(
              child: _buildNavItem(
                label: "Refund",
                context: context,
                icon: Icons.sync_alt_outlined,
                index: 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Refund(),
                    ),
                  );
                },
                isSelected: selectedIndex == 1,
              ),
            ),
            const SizedBox(width: 40), // Space for FAB
            Flexible(
              child: _buildNavItem(
                label: 'Inventory',
                context: context,
                icon: Icons.inventory_2_outlined,
                index: 2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListPage(),
                    ),
                  );
                },
                isSelected: selectedIndex == 2,
              ),
            ),
            Flexible(
              child: _buildNavItem(
                label: 'Users',
                context: context,
                icon: Icons.person_outline,
                index: 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubUserListPage(),
                    ),
                  );
                },
                isSelected: selectedIndex == 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
    required bool isSelected,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers the content
        children: [
          Container(
            padding: const EdgeInsets.all(6.0), // Slightly reduced padding
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              size: 20, // Reduced icon size slightly
              icon,
              color: isSelected
                  ? Colors.green
                  : Colors.black, // Adjust based on selection
            ),
          ),
          const SizedBox(height: 5), // Adds space between the icon and text
          Text(
            label,
            style: const TextStyle(
                color: Colors.black, fontSize: 13), // Reduced font size
          ),
        ],
      ),
    );
  }
}
