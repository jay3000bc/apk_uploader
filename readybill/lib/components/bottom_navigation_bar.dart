import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/pages/home_page.dart';
import 'package:readybill/pages/refund_page.dart';

import 'package:readybill/pages/view_inventory.dart';
import 'package:readybill/pages/view_employee.dart';

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
    double screenHeight = MediaQuery.of(context).size.height;
    return BottomAppBar(
      height: screenHeight * 0.11, // Reduced the height to fit contents better
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              index: 0,
              onTap: () {
                navigatorKey.currentState?.pushReplacement(
                  CupertinoPageRoute(
                    builder: (_) => const HomePage(),
                  ),
                );
              },
              isSelected: selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              label: "Refund",
              icon: Icons.sync_alt_outlined,
              index: 1,
              onTap: () {
                navigatorKey.currentState?.pushReplacement(
                  CupertinoPageRoute(
                    builder: (_) => const RefundPage(),
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
              icon: Icons.inventory_2_outlined,
              index: 2,
              onTap: () {
                navigatorKey.currentState?.pushReplacement(
                  CupertinoPageRoute(
                    builder: (_) => const ProductListPage(),
                  ),
                );
              },
              isSelected: selectedIndex == 2,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              label: 'Employees',
              icon: Icons.person_outline,
              index: 3,
              onTap: () {
                navigatorKey.currentState?.pushReplacement(
                  CupertinoPageRoute(
                    builder: (_) => const EmployeeListPage(),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: isSelected ? green2 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              size: 20,
              icon,
              color: isSelected ? black : green2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: green2,
              fontSize: 12,
              fontFamily: 'Roboto-Regular',
            ),
          ),
        ],
      ),
    );
  }
}
