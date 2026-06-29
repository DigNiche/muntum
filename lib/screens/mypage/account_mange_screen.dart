import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/components/profile_menu_item.dart';

class AccountMangeScreen extends StatefulWidget {
  const AccountMangeScreen({super.key});

  @override
  State<AccountMangeScreen> createState() => _AccountMangeScreenState();
}

class _AccountMangeScreenState extends State<AccountMangeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: "arrow_left.svg",
            center: "계정관리",
            onLeadingTap: () {
              Navigator.pop(context);
            },
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      color: AppColors.lineStrong,
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radius_10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "가입한 이메일",
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'hhjj@gmail.com',
                        style: AppTypography.button2.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                ProfileMenuItem(onTap: () {}, text: '비밀번호 변경'),
                ProfileMenuItem(
                  onTap: () {
                    showPopupWidget(
                      context: context,
                      title: '로그아웃 하시겠어요?',
                      description: '',
                      text1: '취소',
                      text2: '로그아웃하기',
                      onText1Tap: () {
                        Navigator.pop(context);
                      },
                      onText2Tap: () {
                        // 로그아웃
                        Navigator.pop(context);
                      },
                    );
                  },
                  text: '로그아웃',
                ),
                ProfileMenuItem(
                  onTap: () {
                    showPopupWidget(
                      context: context,
                      title: '정말 탈퇴하시겠습니까?',
                      description: '문틈과 함께 했던\n모든 활동 정보가 삭제되며, 복구할 수 없습니다.',
                      text1: '아니요',
                      text2: '탈퇴하기',
                      text2Color: AppColors.error,
                      onText1Tap: () {
                        Navigator.pop(context);
                      },
                      onText2Tap: () {
                        // 탈퇴
                        Navigator.pop(context);
                      },
                    );
                  },
                  text: '회원 탈퇴',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
