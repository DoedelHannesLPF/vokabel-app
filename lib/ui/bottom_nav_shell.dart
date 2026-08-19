import 'package:flutter/material.dart';

import 'home_tab.dart';
import 'library_tab.dart';
import 'account_tab.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      HomeTab(),
      LibraryTab(),
      AccountTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Startseite',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Bibliothek',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class IndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const IndexedStack({super.key, required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int i = 0; i < children.length; i++)
          if (i == index) Positioned.fill(child: children[i]),
      ],
    );
  }
}

