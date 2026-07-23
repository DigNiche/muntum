import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/animated_scrap_icon.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/pre_update.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/utils/program_scrap.dart';

class ProgramDetailAppBar extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;
  final bool showTitle;
  final VoidCallback onBack;

  const ProgramDetailAppBar({
    super.key,
    required this.program,
    required this.entrySource,
    required this.showTitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarWidget(
      centerType: showTitle ? AppBarCenterType.text : AppBarCenterType.none,
      center: program.title,
      leadingIcon: 'arrow_left.svg',
      onLeadingTap: onBack,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: 공유 기능이 준비되면 노출한다.
          if (isReadyForPublish)
            Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: SvgPicture.asset('assets/icons/share.svg', width: 24.r),
            ),
          GestureDetector(
            onTap: () =>
                toggleProgramScrap(context, program, entrySource: entrySource),
            child: ListenableBuilder(
              listenable: ProgramScrapStore.instance,
              builder: (context, _) {
                final isBookmarked = ProgramScrapStore.instance.isScrapped(
                  program,
                );
                return AnimatedScrapIcon(
                  isScrapped: isBookmarked,
                  size: 24,
                  activeColor: AppColors.primary400,
                  inactiveColor: const Color(0xff1c1b1f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
