import 'package:flutter/material.dart';
import 'package:fyp/main.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: SizedBox(
              height: 70,
              width: 360,
              child: Image(
                image: AssetImage("assets/images/netstruct_logo.png"),
                width: 500,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 188, 28, 124),
                  Color.fromARGB(255, 145, 10, 148),
                  Color(0xff5B0D85),
                  Color(0xff19084C),
                ],
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.home, 'Home', 0),
          _buildDrawerItem(
            context,
            Icons.network_check,
            'Network Monitoring',
            1,
          ),
          _buildDrawerItem(
            context,
            Icons.domain,
            'Infrastructure Monitoring',
            2,
          ),
          _buildDrawerItem(
            context,
            Icons.location_on,
            'Environmental Monitoring',
            3,
          ),
          _buildDrawerItem(context, Icons.history, 'Historical Data', 4),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    final mainState = context.findAncestorStateOfType<MainDashboardState>();
    final isSelected = mainState?.selectedIndex == index;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color? tileColor =
        isSelected
            ? (isDarkMode
                ? const Color(0xFF2D1E50) // Dark selected color
                : Colors.deepPurple.shade100) // Light selected color
            : null;

    final Color iconColor = isDarkMode ? Colors.purple.shade100 : Colors.purple;
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black;

    return ListTile(
      tileColor: tileColor,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: () {
        mainState?.onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }
}
