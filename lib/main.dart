import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/onboarding/login.dart';

void main() {
  runApp(const MuntumApp());
}

class MuntumApp extends StatelessWidget {
  const MuntumApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.black,
        ),
      ),
      title: 'Mumtum',
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
