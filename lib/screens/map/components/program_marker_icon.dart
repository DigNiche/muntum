import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/models/program_model.dart';

class ProgramMarkerIcon extends StatelessWidget {
  final ProgramModel program;
  final bool isSelected;
  final ui.Image? decodedNetworkImage;

  const ProgramMarkerIcon({
    super.key,
    required this.program,
    this.isSelected = false,
    this.decodedNetworkImage,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = program.imageUrls.isNotEmpty
        ? program.imageUrls.first
        : '';
    final image = program.images.isNotEmpty ? program.images.first : null;

    return SizedBox(
      width: 64.w,
      height: 64.w,
      child: Center(
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary500 : AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10110F).withValues(alpha: 0.12),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ClipOval(
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isNotEmpty && decodedNetworkImage != null
                  ? RawImage(image: decodedNetworkImage, fit: BoxFit.cover)
                  : imageUrl.isEmpty && image != null
                  ? FittedBox(fit: BoxFit.cover, child: image)
                  : _FallbackMarkerImage(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMarkerImage extends StatelessWidget {
  const _FallbackMarkerImage();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.white, alignment: Alignment.center);
  }
}
