import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/cards/banner.dart';
import 'package:muntum/screens/home/components/banner_carousel.dart';
import 'package:muntum/screens/home/components/cards/curation_card.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/screens/home/components/page_header.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/home/components/cards/vertical_card.dart';
import 'package:muntum/screens/home/components/vertical_card_carousel.dart';
import 'package:muntum/screens/home/search_screen.dart';

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
          child: ColoredBox(
            color: animatedBackgroundColor ?? AppColors.backgroundNormal,
            child: Column(
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
                  icon: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchScreen()),
                      );
                    },
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: SvgPicture.asset(
                        'assets/icons/search.svg',
                        width: 18.sp,
                        height: 18.sp,
                        color: isMyNiche ? AppColors.white : AppColors.gray600,
                      ),
                    ),
                  ),
                  showIndicator: isMyNiche,
                ),
                Expanded(child: isMyNiche ? MyNichePage() : EntirePage()),
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
    return Column(
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              CurationCard(isSecondCard: true),
              CurationCard(isSecondCard: true),
            ],
          ),
        ),
      ],
    );
  }
}

class EntirePage extends StatelessWidget {
  const EntirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
      children: [
        BannerCarousel(banners: [BannerCard(), BannerCard()]),
        SizedBox(height: 48.h),
        SectionHeader1(text: "모아보기", buttonName: '전체보기'),
        SizedBox(height: 8.h),
        VerticalCardCarousel(
          verticalCards: [VerticalCard(), VerticalCard(), VerticalCard()],
        ),
        SectionHeader1(text: "요즘뜨는", buttonName: ''),
        SizedBox(height: 8.h),
        VerticalCardCarousel(
          verticalCards: [VerticalCard(), VerticalCard(), VerticalCard()],
        ),
        SectionHeader1(text: "이번달에 끝나는", buttonName: '전체보기'),
        SizedBox(height: 8.h),
        VerticalCardCarousel(
          verticalCards: [VerticalCard(), VerticalCard(), VerticalCard()],
        ),
      ],
    );
  }
}
