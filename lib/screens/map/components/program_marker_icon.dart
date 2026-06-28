// TODO: 나중에 실제 이미지가 생기면 color 컨테이너 대신 Image.network/Image.asset으로 교체.
// 예: CircleAvatar(backgroundImage: NetworkImage(program.imageUrl))
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';

class ProgramMarkerIcon extends StatelessWidget {
  final Color color;

  const ProgramMarkerIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10110F).withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2.w),
        ),
      ),
    );
  }
}
