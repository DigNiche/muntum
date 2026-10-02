import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';

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
            UserAvatar(
              userId: user?.userId ?? applicant?.userId ?? '',
              imageUrl: user?.profileImageUrl ?? applicant?.profileImageUrl,
              role: role,
              size: 56.r,
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

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.imageUrl,
    required this.role,
    required this.size,
  });

  final String userId;
  final String? imageUrl;
  final String role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isCurator = role.toUpperCase() == 'CURATOR';
    final isManager = role.toUpperCase() == 'MANAGER';
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    return AnimatedBuilder(
      animation: CurrentUserProfileImageStore.instance,
      builder: (context, _) {
        final resolvedUrl = CurrentUserProfileImageStore.instance.resolve(
          userId: userId,
          apiImageUrl: imageUrl,
        );
        return SizedBox(
          width: size + 2.r,
          height: size + 2.r,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: resolvedUrl == null
                    ? fallback
                    : Image.network(
                        resolvedUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
              if (isCurator || isManager)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: SvgPicture.asset(
                    isManager
                        ? 'assets/icons/manager_badge.svg'
                        : 'assets/icons/curator_badge.svg',
                    key: ValueKey('user-role-badge-$userId'),
                    width: 16.r,
                    height: 16.r,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
