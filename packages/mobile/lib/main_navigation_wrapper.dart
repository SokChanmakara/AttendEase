import 'package:flutter/material.dart';
import 'features/home/screens/home_screen.dart';
import 'features/attendance/screens/history_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'core/theme.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 20),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 20),
              label: 'PROFILE',
            ),
          ],
          selectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 9,
            color: AppColors.accent,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
