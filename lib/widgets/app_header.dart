import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final IconData rightIcon;
  final bool showSubtitle;

  const AppHeader({
    super.key,
    required this.title,
    this.leftIcon = Icons.menu,
    this.rightIcon = Icons.notifications_none_rounded,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final lastUpdated = DateFormat('HH:mm').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff0B6EF6),
            Color(0xff16A34A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x400B6EF6),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            child: leftIcon == Icons.menu
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          Scaffold.of(context).openDrawer(),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      leftIcon,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                if (showSubtitle)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Last updated: $lastUpdated',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(
                rightIcon,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
