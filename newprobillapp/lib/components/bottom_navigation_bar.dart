import 'package:flutter/material.dart';
import 'package:newprobillapp/pages/home_page.dart';
import 'package:newprobillapp/pages/refund_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:newprobillapp/pages/view_inventory.dart';
import 'package:newprobillapp/pages/view_employee.dart';

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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return BottomAppBar(
      height: screenHeight * 0.11, // Reduced the height to fit contents better
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFF2CC44),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RefundPage(),
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
          Expanded(
            child: _buildNavItem(
              label: 'Employees',
              context: context,
              icon: Icons.person_outline,
              index: 3,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeListPage(),
                  ),
                );
              },
              isSelected: selectedIndex == 3,
            ),
          ),
        ],
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
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers the content
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                color: Colors.black, fontSize: 12), // Reduced font size
          ),
        ],
      ),
    );
  }
}
