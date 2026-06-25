import 'package:flutter/material.dart';

import '../profile/profile_placeholder_view.dart';
import '../schedule/views/schedule_view.dart';

/// The root shell of the app — provides a bottom navigation bar
/// with three tabs: Lịch làm, Chấm công, Cá nhân.
///
/// Uses [IndexedStack] so each tab preserves its state when switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // The three tab screens. Only ScheduleView is functional right now.
  static const List<Widget> _screens = [
    ScheduleView(),
    ProfilePlaceholderView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all three screens alive while switching tabs.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
