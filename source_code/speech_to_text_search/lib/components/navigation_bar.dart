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
      height: 90,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFF2CC44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildNavItem(
                label: 'Home',
                context: context,
                icon: Icons.home_outlined,
                index: 0,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchApp(),
                    ),
                  );
                },
                isSelected: selectedIndex == 0,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                label: "Refund",
                context: context,
                icon: Icons.sync_alt_outlined,
                index: 1,
                onTap: () {
                  Navigator.pushReplacement(
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
            Expanded(
              child: _buildNavItem(
                label: 'Inventory',
                context: context,
                icon: Icons.inventory_2_outlined,
                index: 2,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListPage(),
                    ),
                  );
                },
                isSelected: selectedIndex == 2,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                label: 'Users',
                context: context,
                icon: Icons.person_outline,
                index: 3,
                onTap: () {
                  Navigator.pushReplacement(
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
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              size: 20,
              icon,
              color: isSelected
                  ? Colors.green
                  : Colors.black, // Adjust based on selection
            ),
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.black, fontSize: 11.5)),
      ],
    );
  }
}
