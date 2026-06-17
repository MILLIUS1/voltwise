import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final IconData rightIcon;
  final bool showSubtitle;

  const AppHeader({
    super.key,
    required this.title,
    this.leftIcon = Icons.menu,
    this.rightIcon = Icons.notifications_none,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Row(
        children: [
          if (leftIcon == Icons.menu)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          else
            IconButton(
              icon: Icon(leftIcon),
              onPressed: () => Navigator.maybePop(context),
            ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(rightIcon),
        ],
      ),
    );
  }
}
