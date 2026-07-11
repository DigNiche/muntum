import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/models/program_model.dart';

class ProgramMarkerIcon extends StatelessWidget {
  final ProgramModel program;
  final bool isSelected;

  const ProgramMarkerIcon({
    super.key,
    required this.program,
    this.isSelected = false,
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
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackMarkerImage(title: program.title),
                    )
                  : image != null
                  ? FittedBox(fit: BoxFit.cover, child: image)
                  : _FallbackMarkerImage(title: program.title),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMarkerImage extends StatelessWidget {
  final String title;

  const _FallbackMarkerImage({required this.title});

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? '?' : title.trim().characters.first;
    return Container(
      color: AppColors.primary400,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.gray900,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
