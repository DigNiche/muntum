import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

void main() {
  runApp(const MuntumApp());
}

class MuntumApp extends StatelessWidget {
  const MuntumApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        backgroundColor: AppColors.backgroundNormal,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "페이지 타이틀/대제목",
                style: AppTypography.display.copyWith(
                  color: AppColors.primary400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
