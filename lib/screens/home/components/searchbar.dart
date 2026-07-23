import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/keyword_chip.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<String> selectedKeywords;
  final ValueChanged<String>? onKeywordDeleted;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onClear,
    this.selectedKeywords = const [],
    this.onKeywordDeleted,
    this.backgroundColor,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onFocusChange() {
    setState(() {
      isFocused = _focusNode.hasFocus;
    });
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: AppColors.gray200, width: 1.0.w),
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
        color: widget.backgroundColor,
      ),
      padding: widget.selectedKeywords.isEmpty
          ? EdgeInsets.only(left: 12.w, right: 8.w, top: 12.h, bottom: 12.h)
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
                    color: AppColors.gray900,
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
                          readOnly: widget.readOnly,
                          autofocus: widget.autofocus,
                          onTap: widget.onTap,
                          onTapOutside: (event) {
                            _focusNode.unfocus();
                          },
                          cursorColor: AppColors.gray900,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: "새로운 곳을 발견해보세요.",
                            hintStyle: AppTypography.body2.copyWith(
                              color: AppColors.gray500,
                            ),
                            suffixIcon:
                                widget.readOnly ||
                                    widget.controller.text.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () {
                                      widget.controller.clear();
                                      widget.onClear?.call();
                                      _focusNode.unfocus();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 12.w),
                                      child: Container(
                                        width: 16.r,
                                        height: 16.r,
                                        padding: EdgeInsets.all(1.r),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.gray400,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/icons/close.svg',
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            suffixIconConstraints: BoxConstraints(
                              minHeight: 16.r,
                              minWidth: 16.r,
                            ),
                            border: InputBorder.none,
                          ),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.gray900,
                          ),
                          onSubmitted: widget.onSubmitted,
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onTap,
                          child: SingleChildScrollView(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
