import 'package:flutter/material.dart';
import 'package:muntum/gates/role_gate.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = false;
    if (!isLoggedIn) {
      return LoginScreen();
    }
    return RoleGate();
  }
}
