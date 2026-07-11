import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/searchbar.dart';

enum AppBarCenterType { text, searchbar, none }

class AppBarWidget extends StatefulWidget {
  final String leadingIcon;
  final Widget? trailing;
  final AppBarCenterType centerType;
  final String center;
  final VoidCallback? onLeadingTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onClear;
  final List<String> selectedKeywords;
  final ValueChanged<String>? onKeywordDeleted;
  final VoidCallback? onSearchTap;
  final Color? leadingColor;
  final bool searchAutofocus;
  const AppBarWidget({
    super.key,
    this.trailing,
    required this.centerType,
    required this.leadingIcon,
    this.center = '',
    this.onLeadingTap,
    this.searchController,
    this.onSearchSubmitted,
    this.onClear,
    this.selectedKeywords = const [],
    this.onKeywordDeleted,
    this.onSearchTap,
    this.leadingColor,
    this.searchAutofocus = false,
  });

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();
}

class _AppBarWidgetState extends State<AppBarWidget> {
  @override
  Widget build(BuildContext context) {
    final isSearchBar = widget.centerType == AppBarCenterType.searchbar;
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onLeadingTap,
            child: SizedBox(
              width: 24.w,
              height: 24.h,
              child: SvgPicture.asset(
                'assets/icons/${widget.leadingIcon}',
                width: 10.w,
                height: 18.h,
                color: widget.leadingColor ?? AppColors.gray900,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          _buildCenter(),
          if (!isSearchBar) ...[
            SizedBox(width: 16.w),
            SizedBox(
              width: (widget.trailing == null) ? 24.w : null,
              child: (widget.trailing != null) ? widget.trailing! : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenter() {
    switch (widget.centerType) {
      case AppBarCenterType.searchbar:
        return Expanded(
          child: SearchBarWidget(
            controller: widget.searchController!,
            onSubmitted: widget.onSearchSubmitted,
            onClear: widget.onClear,
            selectedKeywords: widget.selectedKeywords,
            onKeywordDeleted: widget.onKeywordDeleted,
            onTap: widget.onSearchTap,
            autofocus: widget.searchAutofocus,
          ),
        );
      case AppBarCenterType.text:
        return Expanded(
          child: Center(
            child: Text(
              widget.center,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
          ),
        );
      case AppBarCenterType.none:
        return SizedBox();
    }
  }
}
