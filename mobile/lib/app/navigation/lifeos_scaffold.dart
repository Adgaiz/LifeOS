import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class LifeOsScaffold extends StatelessWidget {
  const LifeOsScaffold({
    required this.selectedIndex,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final int selectedIndex;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) {
            return;
          }
          switch (index) {
            case 0:
              context.go('/today');
              return;
            case 1:
              context.go('/vision');
              return;
            case 2:
              context.go('/goals');
              return;
            case 3:
              context.go('/diary');
              return;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: '今天',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: '愿景',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: '目标',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: '日记',
          ),
        ],
      ),
    );
  }
}
