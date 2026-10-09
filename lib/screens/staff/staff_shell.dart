import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'books_page.dart';
import 'circulation_page.dart';
import 'members_page.dart';
import 'reports_page.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _i = 0;

  static const _pages = <Widget>[
    CirculationPage(),
    StaffBooksPage(),
    MembersPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_i), child: _pages[_i]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded), label: 'Sirkulasi'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_rounded), label: 'Buku'),
          NavigationDestination(
              icon: Icon(Icons.groups_rounded), label: 'Anggota'),
          NavigationDestination(
              icon: Icon(Icons.insights_rounded), label: 'Laporan'),
        ],
      ),
      backgroundColor: AppColors.bg,
    );
  }
}
