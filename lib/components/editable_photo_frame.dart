import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';

/// Reserve layout space for a delete button protruding above/right of a photo.
/// Its original offsets remain relative to the thumbnail, while painting and
/// hit testing both stay within this frame and the enclosing scroll viewport.
class EditablePhotoFrame extends StatelessWidget {
  const EditablePhotoFrame({
    super.key,
    required this.thumbnail,
    required this.thumbnailSize,
    required this.topOffset,
    required this.rightOffset,
    required this.buttonSize,
    required this.iconSize,
    required this.onRemove,
  });

  final Widget thumbnail;
  final Size thumbnailSize;
  final double topOffset;
  final double rightOffset;
  final double buttonSize;
  final double iconSize;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final topSpace = math.max(0.0, -topOffset);
    final rightSpace = math.max(0.0, -rightOffset);
    return SizedBox(
      width: thumbnailSize.width + rightSpace,
      height: thumbnailSize.height + topSpace,
      child: Stack(
        children: [
          Positioned(
            top: topSpace,
            left: 0,
            width: thumbnailSize.width,
            height: thumbnailSize.height,
            child: SizedBox(
              key: const ValueKey('editable-photo-thumbnail'),
              child: thumbnail,
            ),
          ),
          Positioned(
            top: topSpace + topOffset,
            right: rightSpace + rightOffset,
            child: GestureDetector(
              key: const ValueKey('photo-remove-button'),
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.gray900,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
