import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/profile_avatar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

/// Displays an author's avatar, name and optional formatted creation date.
///
/// Medium variants use a 12.w avatar-to-text gap; the large variant uses 16.w.
/// Screen-specific
/// actions remain in [trailing] so visibility and permissions stay with callers.
class AuthorProfile extends StatelessWidget {
  /// Creates the medium profile used for published posts and author menus.
  const AuthorProfile.standard({
    super.key,
    required this.name,
    required this.createdAt,
    this.userId,
    this.imageUrl,
    this.role,
    this.trailing,
  }) : avatarSize = ProfileAvatarSize.medium;

  /// Creates the medium profile with a caller-provided change-request action.
  const AuthorProfile.changeRequest({
    super.key,
    required this.name,
    required this.createdAt,
    required Widget this.trailing,
    this.userId,
    this.imageUrl,
    this.role,
  }) : avatarSize = ProfileAvatarSize.medium;

  /// Creates the large profile used in the curation review detail header.
  const AuthorProfile.large({
    super.key,
    required this.name,
    required this.createdAt,
    this.userId,
    this.imageUrl,
    this.role,
    this.trailing,
  }) : avatarSize = ProfileAvatarSize.large;

  /// The displayed author name.
  final String name;

  /// The already formatted date, without the 작성일 prefix; empty hides the line.
  final String createdAt;

  /// The author identifier used to resolve the current profile image.
  final String? userId;

  /// The optional remote profile image.
  final String? imageUrl;

  /// The role used to select the curator or manager badge.
  final String? role;

  /// The optional menu or change-request action owned by the screen.
  final Widget? trailing;

  /// The avatar and badge dimensions fixed by the selected design variant.
  final ProfileAvatarSize avatarSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ProfileAvatar(
        userId: userId,
        imageUrl: imageUrl,
        role: role,
        size: avatarSize,
      ),
      SizedBox(width: avatarSize == ProfileAvatarSize.large ? 16.w : 12.w),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (avatarSize == ProfileAvatarSize.large
                          ? AppTypography.headline1
                          : AppTypography.headline3)
                      .copyWith(color: AppColors.gray800),
            ),
            if (createdAt.trim().isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                '작성일 $createdAt',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
    ],
  );
}
