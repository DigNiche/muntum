import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';

enum ActionBottomSheetType { scrapLogin, reportLogin, reportSubmit }

Future<void> showActionBottomSheet(
  BuildContext context, {
  required ActionBottomSheetType type,
  VoidCallback? onPrimaryTap,
}) {
  final content = switch (type) {
    ActionBottomSheetType.scrapLogin => const _ActionBottomSheetContent(
      title: '마음에 드는 프로그램을 발견했나요?',
      description: '스크랩은 로그인 이후 이용할 수 있어요.\n로그인하고 마음에 드는 프로그램을 스크랩 해보세요.',
      buttonText: '로그인 하기',
      assetPath: 'assets/icons/bottom_sheet/scrap.svg',
      assetSize: 140,
      opensLogin: true,
    ),
    ActionBottomSheetType.reportLogin => const _ActionBottomSheetContent(
      title: '프로그램 제보를 원하시나요?',
      description: '제보를 하기 위해 로그인이 필요해요.\n아무도 모르는 나만의 장소, 로그인 후 제보해주세요!',
      buttonText: '로그인 하기',
      lottiePath: 'assets/lottie/report_submit.lottie',
      assetSize: 120,
      opensLogin: true,
    ),
    ActionBottomSheetType.reportSubmit => _ActionBottomSheetContent(
      title: '나만 아는 문화 프로그램을 발견했나요?',
      description: '제보하면 문화발굴단 팀이 검토 후\n프로그램으로 등록해드려요!',
      buttonText: '제보하기',
      lottiePath: 'assets/lottie/report_submit.lottie',
      assetSize: 120,
      onPrimaryTap: onPrimaryTap,
    ),
  };

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dimMedium,
    builder: (_) => content,
  );
}

class _ActionBottomSheetContent extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final String? assetPath;
  final String? lottiePath;
  final double assetSize;
  final bool opensLogin;
  final VoidCallback? onPrimaryTap;

  const _ActionBottomSheetContent({
    required this.title,
    required this.description,
    required this.buttonText,
    this.assetPath,
    this.lottiePath,
    required this.assetSize,
    this.opensLogin = false,
    this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28.w, 12.h, 28.w, 34.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 14.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          SizedBox(height: 36.h),
          _BottomSheetAsset(
            assetPath: assetPath,
            lottiePath: lottiePath,
            size: assetSize,
          ),
          SizedBox(height: 34.h),
          ButtonSolid(
            text: buttonText,
            textColor: AppColors.white,
            boxColor: AppColors.black,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            onTap: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              if (opensLogin) {
                navigator.push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }
              onPrimaryTap?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _BottomSheetAsset extends StatelessWidget {
  final String? assetPath;
  final String? lottiePath;
  final double size;

  const _BottomSheetAsset({
    required this.assetPath,
    required this.lottiePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (lottiePath != null) {
      return Lottie.asset(
        lottiePath!,
        width: size.w,
        height: size.w,
        repeat: false,
      );
    }
    return SvgPicture.asset(assetPath!, width: size.w, height: size.w);
  }
}
