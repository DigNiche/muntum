import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/searchbar.dart';

enum AppBarCenterType { text, searchbar, none }

class AppBarWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isSearchBar = centerType == AppBarCenterType.searchbar;
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
      child: isSearchBar ? _buildSearchLayout() : _buildStandardLayout(),
    );
  }

  Widget _buildSearchLayout() {
    return Row(
      children: [
        _buildLeading(),
        SizedBox(width: 16.w),
        Expanded(
          child: SearchBarWidget(
            controller: searchController!,
            onSubmitted: onSearchSubmitted,
            onClear: onClear,
            selectedKeywords: selectedKeywords,
            onKeywordDeleted: onKeywordDeleted,
            onTap: onSearchTap,
            autofocus: searchAutofocus,
          ),
        ),
      ],
    );
  }

  Widget _buildStandardLayout() {
    return NavigationToolbar(
      leading: _buildLeading(),
      middle: centerType == AppBarCenterType.text
          ? Text(
              center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            )
          : null,
      trailing: trailing ?? SizedBox(width: 24.w, height: 24.h),
      centerMiddle: true,
      middleSpacing: 16.w,
    );
  }

  Widget _buildLeading() {
    return GestureDetector(
      onTap: onLeadingTap,
      child: SizedBox(
        width: 24.w,
        height: 24.h,
        child: SvgPicture.asset(
          'assets/icons/$leadingIcon',
          width: 10.w,
          height: 18.h,
          colorFilter: ColorFilter.mode(
            leadingColor ?? AppColors.gray900,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
