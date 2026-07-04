import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/user_keyword.dart';

class KeywordChangeScreen extends StatefulWidget {
  const KeywordChangeScreen({super.key});

  @override
  State<KeywordChangeScreen> createState() => _KeywordChangeScreenState();
}

class _KeywordChangeScreenState extends State<KeywordChangeScreen> {
  bool isEdit = false;
  bool isDoneEditing = false;
  Color trailingTextColor = AppColors.gray900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: isEdit ? 'arrow_left.svg' : 'close.svg',
            center: isEdit ? '키워드 편집' : "키워드",
            onLeadingTap: () {
              if (isEdit) {
                isEdit = false;
                setState(() {});
              } else {
                Navigator.pop(context);
              }
            },
            trailing: GestureDetector(
              onTap: () {
                setState(() {
                  isEdit = !isEdit;
                  if (isEdit) {
                    trailingTextColor = AppColors.gray500;
                  } else {
                    trailingTextColor = AppColors.gray900;
                  }
                });
              },
              child: Text(
                isEdit ? '저장' : '편집',
                style: AppTypography.button2.copyWith(color: trailingTextColor),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "내 키워드(${userKeywords.length})",
                    style: AppTypography.headline2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 8.h,
                        children: isEdit
                            ? entireKeywords.map((keyword) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.0.h,
                                  ),
                                  child: Row(
                                    spacing: 12.w,
                                    children: [
                                      Container(
                                        width: 20.w,
                                        height: 20.h,
                                        padding: EdgeInsets.all(2.r),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: userKeywords.contains(keyword)
                                              ? AppColors.gray900
                                              : AppColors.gray100,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              trailingTextColor =
                                                  AppColors.gray900;
                                              if (userKeywords.contains(
                                                keyword,
                                              )) {
                                                userKeywords.remove(keyword);
                                              } else {
                                                userKeywords.add(keyword);
                                              }
                                            });
                                          },
                                          child: SvgPicture.asset(
                                            userKeywords.contains(keyword)
                                                ? 'assets/icons/check.svg'
                                                : 'assets/icons/plus.svg',
                                            width: 20.w,
                                            color:
                                                userKeywords.contains(keyword)
                                                ? AppColors.white
                                                : AppColors.gray600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        keyword,
                                        style: AppTypography.body1.copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                            : userKeywords
                                  .map(
                                    (keyword) => Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.0.h,
                                      ),
                                      child: Row(
                                        spacing: 12.w,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(2.r),
                                            width: 20.w,
                                            height: 20.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: AppColors.gray100,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/icons/minus.svg',
                                              width: 20.w,
                                              color: AppColors.gray600,
                                            ),
                                          ),
                                          Text(
                                            keyword,
                                            style: AppTypography.body1.copyWith(
                                              color: AppColors.gray900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
