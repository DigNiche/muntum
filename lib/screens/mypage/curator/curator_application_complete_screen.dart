import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';

class CuratorApplicationCompleteScreen extends StatelessWidget {
  const CuratorApplicationCompleteScreen({super.key});

  void _goToProfile(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MainNavigationScreen(initialIndex: 4),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              trailing: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _goToProfile(context),
                child: SizedBox(
                  width: 44.r,
                  height: 44.r,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/close.svg',
                      width: 20.r,
                      height: 20.r,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/curator_apply_complete.lottie',
                    width: 140.r,
                    height: 140.r,
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '지원해 주셔서 감사합니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.title3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '확인 후 영업일 기준 1~2일 내로\n큐레이터 승인 결과 및 권한이 부여됩니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 48.h),
              child: SizedBox(
                width: double.infinity,
                child: ButtonSolid(
                  text: '프로필로 이동',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  onTap: () => _goToProfile(context),
                  padding: EdgeInsets.only(top: 14.h, bottom: 13.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
