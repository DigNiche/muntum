import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:muntum/gates/role_gate.dart';
import 'package:muntum/screens/onboarding/login.dart';

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

  Future<void> _initialize() async {
    // 로그인 체크
    // 토큰 체크
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = true;
    if (!isLoggedIn) {
      return LoginScreen();
    }
    return RoleGate();
  }
}
