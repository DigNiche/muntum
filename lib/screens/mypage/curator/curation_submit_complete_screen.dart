import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/written_program_list_page.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';

class CurationSubmitCompleteScreen extends StatelessWidget {
  const CurationSubmitCompleteScreen({super.key});

  void _goToProfile(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MainNavigationScreen(initialIndex: 4),
      ),
      (_) => false,
    );
  }

  void _showSubmittedContent(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const WrittenProgramList()),
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
                    repeat: false,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '소중한 글을 남겨주셔서\n감사합니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.title3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '확인 후 영업일 기준 1~2일 내로 등록됩니다.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ButtonSolid(
                      text: '프로필로 이동',
                      textColor: AppColors.white,
                      boxColor: AppColors.black,
                      padding: EdgeInsets.zero,
                      onTap: () => _goToProfile(context),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  TextButton(
                    onPressed: () => _showSubmittedContent(context),
                    child: Text(
                      '작성 내용 확인하기',
                      style: AppTypography.button3.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
