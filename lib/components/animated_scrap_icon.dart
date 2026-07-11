import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';

class AnimatedScrapIcon extends StatelessWidget {
  final bool isScrapped;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedScrapIcon({
    super.key,
    required this.isScrapped,
    this.size = 24,
    this.activeColor = AppColors.primary400,
    this.inactiveColor = AppColors.gray400,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(isScrapped),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final pulse = math.sin(value * math.pi);
        final scale = isScrapped ? 1 + pulse * 0.18 : 1 - pulse * 0.08;
        return Transform.scale(scale: scale, child: child);
      },
      child: SvgPicture.asset(
        isScrapped ? 'assets/icons/scrap-filled.svg' : 'assets/icons/scrap.svg',
        width: size.r,
        height: size.r,
        colorFilter: ColorFilter.mode(
          isScrapped ? activeColor : inactiveColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
