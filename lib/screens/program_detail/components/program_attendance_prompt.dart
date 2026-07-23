import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

enum _AttendanceRating { disliked, liked }

class ProgramAttendancePrompt extends StatefulWidget {
  const ProgramAttendancePrompt({super.key});

  @override
  State<ProgramAttendancePrompt> createState() =>
      _ProgramAttendancePromptState();
}

class _ProgramAttendancePromptState extends State<ProgramAttendancePrompt> {
  _AttendanceRating? _rating;
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        padding: _rating == null
            ? EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w)
            : EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
          color: AppColors.gray100,
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpanded,
              child: _rating == null
                  ? _buildQuestionHeader()
                  : _buildRecordedHeader(),
            ),
            if (_isExpanded) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _RatingButton(
                      text: '아쉬웠어요',
                      iconPath: 'assets/icons/thumb_down.svg',
                      selectedIconPath: 'assets/icons/thumb_down_filled.svg',
                      isSelected: _rating == _AttendanceRating.disliked,
                      onTap: () => _selectRating(_AttendanceRating.disliked),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _RatingButton(
                      text: '좋았어요',
                      iconPath: 'assets/icons/thumb_up.svg',
                      selectedIconPath: 'assets/icons/thumb_up_filled.svg',
                      isSelected: _rating == _AttendanceRating.liked,
                      onTap: () => _selectRating(_AttendanceRating.liked),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 프로그램 다녀오셨나요?',
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 2.h),
            Text(
              '평가하고 취향을 기록해보세요!',
              style: AppTypography.button3.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
        _buildArrow(),
      ],
    );
  }

  Widget _buildRecordedHeader() {
    final isLiked = _rating == _AttendanceRating.liked;
    return Row(
      children: [
        SvgPicture.asset(
          isLiked ? 'assets/liked.svg' : 'assets/disliked.svg',
          width: 24.r,
          height: 24.r,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            isLiked ? '"좋았어요!"로 기록했어요' : '"아쉬웠어요"로 기록했어요',
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        _buildArrow(),
      ],
    );
  }

  Widget _buildArrow() {
    return SvgPicture.asset(
      _isExpanded ? 'assets/icons/arrow_up.svg' : 'assets/icons/arrow_down.svg',
      width: 24.r,
      height: 24.r,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectRating(_AttendanceRating rating) {
    setState(() {
      _rating = _rating == rating ? null : rating;
      if (_rating == null) {
        _isExpanded = true;
      } else {
        _isExpanded = false;
      }
    });
  }
}

class _RatingButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final String selectedIconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.text,
    required this.iconPath,
    required this.selectedIconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? AppColors.white : AppColors.gray400;
    final textColor = isSelected ? AppColors.white : AppColors.gray800;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray900 : AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isSelected ? selectedIconPath : iconPath,
              width: 18.r,
              height: 18.r,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            SizedBox(width: 6.w),
            Text(text, style: AppTypography.button3.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}
