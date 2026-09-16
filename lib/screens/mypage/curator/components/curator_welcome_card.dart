import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class CuratorWelcomeCard extends StatelessWidget {
  const CuratorWelcomeCard({
    super.key,
    required this.nickname,
    required this.onClose,
    required this.onTapAction,
  });

  final String nickname;
  final VoidCallback onClose;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.white, AppColors.primary50],
          stops: [0.25, 1],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              key: const ValueKey('curator-welcome-close'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: SvgPicture.asset(
                  'assets/icons/close.svg',
                  width: 20.r,
                  height: 20.r,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Lottie.asset(
            'assets/lottie/curator_celebration.lottie',
            repeat: false,
            width: 240.w,
            height: 110.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 8.h),
          Text(
            '$nickname님,\n큐레이터가 되신 것을 축하합니다!',
            textAlign: TextAlign.center,
            style: AppTypography.title4.copyWith(
              color: AppColors.gray900,
              height: 1.45,
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapAction,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '지금 바로 활동을 시작해보세요',
                    style: AppTypography.body3.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  SvgPicture.asset(
                    'assets/icons/arrow_right-small.svg',
                    width: 16.r,
                    height: 16.r,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray400,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
