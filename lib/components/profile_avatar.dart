import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';
import 'package:muntum/utils/image_url.dart';

enum ProfileAvatarSize {
  large(56, 20),
  medium(40, 16),
  small(24, 12);

  const ProfileAvatarSize(this.diameter, this.badgeDiameter);
  final double diameter;
  final double badgeDiameter;
}

/// All dimensions are diameters. The role badge stays inside the layout box.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.role,
    this.size = ProfileAvatarSize.medium,
    this.localImagePath,
    this.useCurrentUserImage = true,
    this.showRoleBadge = true,
  });

  final String? userId;
  final String? imageUrl;
  final String? role;
  final ProfileAvatarSize size;
  final String? localImagePath;
  final bool useCurrentUserImage;
  final bool showRoleBadge;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CurrentUserProfileImageStore.instance,
    builder: (context, _) {
      final diameter = size.diameter.r;
      final badgeDiameter = size.badgeDiameter.r;
      final resolvedUrl = useCurrentUserImage
          ? CurrentUserProfileImageStore.instance.resolve(
              userId: userId,
              apiImageUrl: imageUrl,
            )
          : normalizeOptionalImageUrl(imageUrl);
      final url = normalizeOptionalImageUrl(resolvedUrl);
      final fallback = Image.asset(
        'assets/default_profile_img.jpg',
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
      final image = localImagePath != null
          ? Image.file(
              File(localImagePath!),
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : url == null
          ? fallback
          : Image.network(
              url,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            );
      final normalizedRole = role?.toUpperCase();
      final badgeAsset = switch (normalizedRole) {
        'MANAGER' => 'assets/icons/manager_badge.svg',
        'CURATOR' => 'assets/icons/curator_badge.svg',
        _ => null,
      };
      return SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(child: image),
            if (showRoleBadge && badgeAsset != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  badgeAsset,
                  key: ValueKey('user-role-badge-${userId ?? ''}'),
                  width: badgeDiameter,
                  height: badgeDiameter,
                ),
              ),
          ],
        ),
      );
    },
  );
}
