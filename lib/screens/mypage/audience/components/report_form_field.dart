import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ReportFormField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? value;
  final String? errorText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool showChevron;

  const ReportFormField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.value,
    this.errorText,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.showChevron = false,
  });

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.button3.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            ignoring: readOnly || onTap != null,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              maxLines: maxLines,
              minLines: maxLines,
              style: AppTypography.body1.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: value ?? hintText,
                hintStyle: AppTypography.body1.copyWith(
                  color: value == null ? AppColors.gray400 : AppColors.gray900,
                ),
                suffixIcon: showChevron
                    ? Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: SvgPicture.asset(
                          'assets/icons/arrow_right-small.svg',
                          width: 16.w,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gray500,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: BoxConstraints(
                  minWidth: 28.w,
                  minHeight: 16.h,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: maxLines == 1 ? 13.h : 12.h,
                ),
                enabledBorder: _border(AppColors.lineStrong),
                focusedBorder: _border(AppColors.gray900),
                errorBorder: _border(AppColors.error),
                focusedErrorBorder: _border(AppColors.error),
                border: _border(AppColors.lineStrong),
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.error, size: 14.r, color: AppColors.error),
              SizedBox(width: 4.w),
              Text(
                errorText!,
                style: AppTypography.caption3.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: BorderSide(color: color, width: 1.w),
    );
  }
}
