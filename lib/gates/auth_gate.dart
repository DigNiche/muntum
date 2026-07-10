import 'package:flutter/material.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/gates/role_gate.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/services/taste_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _resolveEntry();
  }

  Future<Widget> _resolveEntry() async {
    try {
      final session = await AuthService().refresh();
      if (session == null) return const LoginScreen();

      final nickname =
          session.nickname ?? await TokenStore.instance.readNickname();
      if (nickname == null || nickname.trim().isEmpty) {
        return const NicknameScreen();
      }

      final keywords = await TasteService().fetchMyKeywords();
      if (keywords.selectedKeywords.length < 3) {
        return const KeywordScreen();
      }
      return RoleGate();
    } catch (_) {
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _entryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}
