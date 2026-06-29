import 'package:flutter/material.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';

enum UserRole { user, admin }

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = UserRole.user;
    if (userRole == UserRole.user) {
      return MainNavigationScreen();
    }
    return MainNavigationScreen();
  }
}
