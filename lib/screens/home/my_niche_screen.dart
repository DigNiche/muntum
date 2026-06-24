import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/page_header.dart';

enum ScreenTypes { myNiche, entire }

class MyNicheScreen extends StatefulWidget {
  const MyNicheScreen({super.key});

  @override
  State<MyNicheScreen> createState() => _MyNicheScreenState();
}

class _MyNicheScreenState extends State<MyNicheScreen> {
  ScreenTypes screenType = ScreenTypes.myNiche;

  @override
  Widget build(BuildContext context) {
    final isMyNiche = screenType == ScreenTypes.myNiche;

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      tween: ColorTween(
        end: isMyNiche ? AppColors.gray900 : AppColors.backgroundNormal,
      ),
      builder: (context, animatedBackgroundColor, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            // Android
            statusBarIconBrightness: isMyNiche
                ? Brightness.light
                : Brightness.dark,
            // iOS
            statusBarBrightness: isMyNiche ? Brightness.dark : Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: animatedBackgroundColor,
            body: Column(
              children: [
                SizedBox(height: 50.h),
                PageHeader(
                  firstText: '내취향',
                  firstTextColor: isMyNiche
                      ? AppColors.white
                      : AppColors.gray300,
                  onFirstTextTap: () {
                    setState(() {
                      screenType = ScreenTypes.myNiche;
                    });
                  },
                  secondText: '전체',
                  secondTextColor: isMyNiche
                      ? AppColors.gray600
                      : AppColors.black,
                  onSecondTextTap: () {
                    setState(() {
                      screenType = ScreenTypes.entire;
                    });
                  },
                  icon: SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 24.sp,
                    height: 24.sp,
                    color: isMyNiche ? AppColors.white : AppColors.gray600,
                  ),
                  showIndicator: isMyNiche,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
