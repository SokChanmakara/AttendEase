import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'main_navigation_wrapper.dart';

void main() {
  runApp(const AttendEaseApp());
}

class AttendEaseApp extends StatelessWidget {
  const AttendEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttendEase',
      theme: AppTheme.darkTheme,
      // For demonstration, starting at Login. 
      // In real app, check auth state.
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationWrapper(),
      },
    );
  }
}
