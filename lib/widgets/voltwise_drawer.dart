import 'package:flutter/material.dart';
import '../main.dart';

class VoltWiseDrawer extends StatelessWidget {
  const VoltWiseDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xff0B6EF6),
            ),
            accountName: Text('Millius N. Liswaniso'),
            accountEmail: Text('milliusn@gmail.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.energy_savings_leaf,
                color: Color(0xff0B6EF6),
                size: 36,
              ),
            ),
          ),
          _drawerItem(
            context,
            Icons.person_outline,
            'Profile',
            const ProfilePage(),
          ),
          _drawerItem(
            context,
            Icons.settings_outlined,
            'Settings',
            const SettingsPage(),
          ),
          _drawerItem(
            context,
            Icons.history,
            'Usage History',
            const UsageHistoryPage(),
          ),
          _drawerItem(
            context,
            Icons.help_outline,
            'Help & Support',
            const HelpSupportPage(),
          ),
          _drawerItem(
            context,
            Icons.info_outline,
            'About VoltWise',
            const AboutVoltWisePage(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  static Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xff0B6EF6),
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }
}
