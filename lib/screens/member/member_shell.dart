import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'catalog_page.dart';
import 'history_page.dart';
import 'my_loans_page.dart';

class MemberShell extends StatefulWidget {
  const MemberShell({super.key});

  @override
  State<MemberShell> createState() => _MemberShellState();
}

class _MemberShellState extends State<MemberShell> {
  int _i = 0;

  static const _pages = <Widget>[CatalogPage(), MyLoansPage(), HistoryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
          NavigationDestination(icon: Icon(Icons.explore_rounded), label: 'Katalog'),
          NavigationDestination(icon: Icon(Icons.bookmark_rounded), label: 'Pinjaman'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
        ],
      ),
    );
  }
}
