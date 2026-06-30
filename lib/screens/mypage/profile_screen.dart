import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/account_mange_screen.dart';
import 'package:muntum/screens/mypage/components/profile_menu_item.dart';
import 'package:muntum/screens/mypage/keyword_change_screen.dart';
import 'package:muntum/screens/mypage/nickname_change_screen.dart';
import 'package:muntum/screens/mypage/reportlist_screen.dart';
import 'package:muntum/screens/mypage/settings_screen.dart';
import 'package:muntum/screens/mypage/components/stat_card_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(height: 50.h),
          PageHeader(
            firstText: '프로필',
            icon: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              child: SvgPicture.asset(
                'assets/icons/setting.svg',
                width: 24.w,
                color: AppColors.gray900,
              ),
            ),
            firstTextColor: AppColors.gray900,
            showIndicator: false,
          ),
          // Profile
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              spacing: 16.h,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(radius: 28.r),
                    SizedBox(width: 16.w),
                    Expanded(child: Text("문화발굴단", style: AppTypography.title4)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NickNameChangeScreen(),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/icons/edit.svg',
                        width: 18.w,
                        color: AppColors.gray400,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Color(0xfff8f8f8),
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radius_10,
                    ),
                  ),
                  child: Row(
                    children: [
                      StatCard(
                        title: '키워드',
                        number: '5',
                        onTap: () {
                          pushToScreen(context, KeywordChangeScreen());
                        },
                      ),
                      Container(
                        width: 2.w,
                        color: AppColors.gray200,
                        height: 30.h,
                      ),
                      StatCard(
                        title: '제보내역',
                        number: '2',
                        onTap: () {
                          pushToScreen(context, ReportListScreen());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 8.h, color: AppColors.lineAlternative),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: Column(
              children: [
                ProfileMenuItem(text: '제보하기', onTap: () {}),
                ProfileMenuItem(
                  text: '계정관리',
                  onTap: () {
                    pushToScreen(context, AccountMangeScreen());
                  },
                ),
                ProfileMenuItem(text: '공지사항', onTap: () {}),
                ProfileMenuItem(text: '이용약관', onTap: () {}),
                ProfileMenuItem(text: '버전정보', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void pushToScreen(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
}
