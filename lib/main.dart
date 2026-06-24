import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/my_niche_screen.dart';

void main() {
  runApp(const MuntumApp());
}

class MuntumApp extends StatelessWidget {
  const MuntumApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      minTextAdapt: true,
      splitScreenMode: true,
      // 390x844 UI
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        title: 'Mumtum',
        home: child,
        debugShowCheckedModeBanner: false,
      ),
      child: MyNicheScreen(),
    );
  }
}
