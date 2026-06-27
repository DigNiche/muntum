import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/keyword_chip.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<String> selectedKeywords;
  final ValueChanged<String>? onKeywordDeleted;
  final Color? backgroundColor;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onClear,
    this.selectedKeywords = const [],
    this.onKeywordDeleted,
    this.backgroundColor,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: AppColors.gray200, width: 1.0.w),
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
        color: widget.backgroundColor,
      ),
      padding: widget.selectedKeywords.isEmpty
          ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h)
          : EdgeInsets.only(left: 12.w),
      child: Center(
        child: Stack(
          children: [
            Row(
              spacing: 8.w,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: SvgPicture.asset(
                    'assets/icons/search.svg',
                    color: AppColors.gray500,
                    width: 18.w,
                    height: 18.h,
                  ),
                ),
                Expanded(
                  child: widget.selectedKeywords.isEmpty
                      ? TextField(
                          controller: widget.controller,
                          maxLines: 1,
                          focusNode: _focusNode,
                          onTapOutside: (event) {
                            _focusNode.unfocus();
                          },
                          cursorColor: AppColors.gray900,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: "새로운 곳을 발견해보세요.",
                            hintStyle: AppTypography.body2.copyWith(
                              color: _isFocused
                                  ? AppColors.gray900
                                  : AppColors.gray500,
                            ),
                            suffix: GestureDetector(
                              onTap: () {
                                widget.controller.clear();
                                widget.onClear?.call();
                                _focusNode.unfocus();
                              },
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: SvgPicture.asset(
                                  'assets/icons/circle_close.svg',
                                  color: AppColors.gray500,
                                  width: 16.67.w,
                                  height: 16.67.h,
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.gray900,
                          ),
                          onSubmitted: widget.onSubmitted,
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.selectedKeywords.map((keyword) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: KeywordChip(
                                  text: keyword,
                                  textColor: AppColors.gray900,
                                  outlineColor: AppColors.lineStrong,
                                  showCloseIcon: true,
                                  onCloseTap: () {
                                    widget.onKeywordDeleted?.call(keyword);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
