import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProgramCuratorBadge extends StatelessWidget {
  const ProgramCuratorBadge({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/curator_badge.svg',
    key: const ValueKey('program-curator-badge'),
    width: size ?? 20.w,
    height: size ?? 20.w,
  );
}
