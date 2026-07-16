import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class TextFieldWidget extends StatelessWidget {
  final String hintText;
  final String? label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool isError;
  final String errorText;

  const TextFieldWidget({
    super.key,
    required this.hintText,
    this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.obscureText,
    this.suffixIcon,
    this.focusNode,
    required this.isError,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Column(
            children: [
              Text(
                label!,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        SizedBox(
          height: 48.h,
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            focusNode: focusNode,
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            cursorColor: AppColors.white,
            onTapOutside: (event) {
              focusNode?.unfocus();
            },
            style: AppTypography.body1.copyWith(
              color: isError ? AppColors.gray500 : AppColors.white,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.white.withValues(alpha: 0.1),
              hintText: hintText,
              hintStyle: AppTypography.body1.copyWith(
                color: focusNode?.hasFocus == true
                    ? AppColors.gray800
                    : AppColors.gray500,
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
                child: suffixIcon,
              ),
              suffixIconConstraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 48.h,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: isError
                    ? BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 2.w,
                      )
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: isError
                    ? BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 2.w,
                      )
                    : BorderSide(color: AppColors.primary700, width: 2.w),
              ),
            ),
          ),
        ),
        if (isError)
          Column(
            children: [
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 4.w,
                children: [
                  Transform.translate(
                    offset: Offset(0, 0.5.h),
                    child: SvgPicture.asset(
                      'assets/icons/error.svg',
                      width: 16.w,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    errorText,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
