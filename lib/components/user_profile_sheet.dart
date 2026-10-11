import 'package:flutter/material.dart';
import 'package:muntum/components/profile_avatar.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/models/curator_application_model.dart';

class UserProfileSheet extends StatelessWidget {
  const UserProfileSheet({super.key, this.user, this.applicant})
    : assert(user != null || applicant != null);

  final AdminUserModel? user;
  final CuratorApplicantModel? applicant;

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? applicant?.role ?? '';
    final isCurator = role.toUpperCase() == 'CURATOR';
    final isManager = role.toUpperCase() == 'MANAGER';
    final stats = <(String, String)>[
      ('스크랩', user == null ? '-' : '${user!.scrapCount}'),
      ('제보', user == null ? '-' : '${user!.suggestionCount}'),
      if (isCurator || isManager) ('작성글', '-'),
    ];
    final nickname =
        user?.displayName ??
        ((applicant?.nickname?.trim().isNotEmpty ?? false)
            ? applicant!.nickname!.trim()
            : applicant?.email ?? '사용자');
    final joinedAt = user?.joinedAt ?? applicant?.joinedAt;
    final joinedLabel = joinedAt == null
        ? '-'
        : '${joinedAt.year}.${joinedAt.month.toString().padLeft(2, '0')}.${joinedAt.day.toString().padLeft(2, '0')}';
    return Container(
      key: const ValueKey('user-profile-sheet'),
      width: double.infinity,
      height: 330.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '가입일: $joinedLabel',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ProfileAvatar(
              userId: user?.userId ?? applicant?.userId ?? '',
              imageUrl: user?.profileImageUrl ?? applicant?.profileImageUrl,
              role: role,
              size: ProfileAvatarSize.large,
            ),
            SizedBox(height: 16.h),
            Text(
              nickname,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 4.h),
            Text(
              '가입한 계정',
              style: AppTypography.body3.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: 24.h),
            Container(
              height: 56.h,
              decoration: BoxDecoration(
                color: AppColors.backgroundNormal,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      SizedBox(
                        height: 20.h,
                        child: VerticalDivider(
                          width: 1.w,
                          thickness: 1.w,
                          color: AppColors.lineStrong,
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${stats[i].$1} ${stats[i].$2}',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
