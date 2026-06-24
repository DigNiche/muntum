import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/banner.dart';
import 'package:muntum/screens/home/components/banner_carousel.dart';
import 'package:muntum/screens/home/components/curation_card.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/screens/home/components/page_header.dart';

enum ScreenTypes { myNiche, entire }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScreenTypes screenType = ScreenTypes.myNiche;

  @override
  Widget build(BuildContext context) {
    final isMyNiche = screenType == ScreenTypes.myNiche;

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      tween: ColorTween(
        end: isMyNiche ? AppColors.backgroundDark : AppColors.backgroundNormal,
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
                if (isMyNiche) MyNichePage(),
                if (!isMyNiche) EntirePage(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyNichePage extends StatelessWidget {
  const MyNichePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FilterList(
          listOfChip: [
            FilterChip(
              text: '무료',
              textColor: AppColors.gray400,
              backgroundColor: Color(0x0fffffff),
            ),
            FilterChip(
              text: '이번주',
              textColor: AppColors.gray400,
              backgroundColor: Color(0x0fffffff),
            ),
            FilterChip(
              text: '예약없이',
              textColor: AppColors.gray400,
              backgroundColor: Color(0x0fffffff),
            ),
          ],
        ),
        CurationCard(isSecondCard: true),
        CurationCard(isSecondCard: true),
      ],
    );
  }
}

class EntirePage extends StatelessWidget {
  const EntirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BannerCarousel();
  }
}
