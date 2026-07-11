import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/terms_detail_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '이용약관',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              children: [
                _TermsMenuItem(
                  title: '서비스 이용약관',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TermsDetailScreen(title: '서비스 이용약관'),
                      ),
                    );
                  },
                ),
                _TermsMenuItem(
                  title: '개인정보 처리 방침',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TermsDetailScreen(title: '개인정보 처리방침'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _TermsMenuItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lineStrong, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.body2.copyWith(color: AppColors.gray900),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/arrow_right-small.svg',
              width: 18.w,
              colorFilter: const ColorFilter.mode(
                AppColors.gray500,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
