import 'package:flutter/material.dart';
import 'package:fyp/main.dart';
import 'package:fyp/services/auth_service.dart';
import 'package:fyp/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class AccountMenu extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final AuthService authService;

  const AccountMenu({
    Key? key,
    required this.userData,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle, size: 30, color: Colors.white),
      onPressed: () => _showAccountMenu(context),
    );
  }

  void _showAccountMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final offset = button.localToGlobal(Offset(0, button.size.height));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.grey[700]! : Colors.grey;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/user.png"),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userData?['username'] ?? 'User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified,
                              color: Color.fromARGB(255, 0, 143, 5),
                              size: 16,
                            ),
                          ],
                        ),
                        Text(
                          userData?['email'] ?? 'email@example.com',
                          style: TextStyle(color: secondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: dividerColor),
                _buildAccountMenuItem(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  trailing: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeColor: Colors.blue,
                      );
                    },
                  ),
                ),
                _buildAccountMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {},
                ),
                _buildAccountMenuItem(
                  icon: Icons.logout,
                  title: 'Log out',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthCheckPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "v1.2.11 • Terms & Conditions",
                    style: TextStyle(fontSize: 10, color: secondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
