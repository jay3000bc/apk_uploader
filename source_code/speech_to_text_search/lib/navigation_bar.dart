import 'package:flutter/material.dart';
import 'package:speech_to_text_search/add_product.dart';
import 'package:speech_to_text_search/drawer.dart';
import 'package:speech_to_text_search/refund.dart';
import 'package:speech_to_text_search/search_app.dart';
import 'package:speech_to_text_search/support.dart';
import 'package:speech_to_text_search/transaction_list.dart';
// Import the AddItem screen

class CustomNavigationBar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  CustomNavigationBar({required this.onItemSelected, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 100,
      backgroundColor: Color.fromRGBO(2, 103, 112, 1),
      shadowColor: Colors.black,
      destinations: [
        GestureDetector(
          onTap: () {
            onItemSelected(0);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchApp()), // Navigate to Home screen
            );
          },
          child: CustomNavigationItem(
            iconData: Icons.home,
            label: "Home",
            isSelected: selectedIndex == 0,
            onTap: () {
              onItemSelected(0);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchApp()), // Navigate to Home screen
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            onItemSelected(1);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Refund()), // Navigate to Dashboard screen
            );
          },
          child: CustomNavigationItem(
            iconData: Icons.sync,
            label: "Refund",
            isSelected: selectedIndex == 1,
            onTap: () {
              onItemSelected(1);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Refund()), // Navigate to Dashboard screen
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            onItemSelected(2);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactSupportPage()), // Navigate to Transaction screen
            );
          },
          child: CustomNavigationItem(
            iconData: Icons.question_mark_sharp,
            label: "Support",
            isSelected: selectedIndex == 2,
            onTap: () {
              onItemSelected(2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactSupportPage()), // Navigate to Transaction screen
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            onItemSelected(3);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Sidebar()), // Navigate to Sidebar screen
            );
          },
          child: CustomNavigationItem(
            iconData: Icons.more_horiz,
            label: "More",
            isSelected: selectedIndex == 3,
            onTap: () {
              onItemSelected(3);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Sidebar()), // Navigate to Sidebar screen
              );
            },
          ),
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }
}

class CustomNavigationItem extends StatelessWidget {
  final IconData iconData;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomNavigationItem({
    Key? key,
    required this.iconData,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Color.fromRGBO(2, 103, 112, 1), // Background color for selected item
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white, // Always have a border color
                  width: 2, // Adjust border width as needed
                ),
              ),
              child: Icon(
                iconData,
                color: isSelected ? Color.fromRGBO(2, 103, 112, 1) : Colors.white, // Icon color based on selection
              ),
            ),
            SizedBox(height: 1.0),
            Text(
              label,
              style: TextStyle(
                color: Colors.white, // Text color based on selection
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Bold font for selected item
              ),
            ),
          ],
        ),
      ),
    );
  }
}
