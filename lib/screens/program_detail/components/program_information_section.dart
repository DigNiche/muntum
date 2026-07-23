import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';

class ProgramInformationSection extends StatelessWidget {
  final ProgramModel program;
  final ValueChanged<String> onTapContact;
  final VoidCallback? onTapWebsite;

  const ProgramInformationSection({
    super.key,
    required this.program,
    required this.onTapContact,
    this.onTapWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6.h,
      children: [
        _LocationDescription(program: program),
        _ProgramDescription(title: '기간', body: program.detailDateText),
        _ProgramDescription(title: '시간', body: program.availableTime),
        _ProgramDescription(title: '가격', body: program.cost),
        _ProgramDescription(
          title: '사전예약',
          body: program.isReservationNeeded ? '필요' : '불필요',
        ),
        _ProgramRelatedInfoDescription(
          title: '관련정보',
          body: program.phoneNumber,
          onTapContact: onTapContact,
        ),
        _ProgramDescription(
          title: '링크',
          body: program.link.isEmpty ? '' : '바로가기',
          onTap: program.link.isEmpty ? null : onTapWebsite,
        ),
      ],
    );
  }
}

class _LocationDescription extends StatelessWidget {
  final ProgramModel program;

  const _LocationDescription({required this.program});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 70.w,
              child: Text(
                '위치',
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
            SizedBox(width: 20.w),
            Text(
              program.locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body1.copyWith(color: AppColors.gray900),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 90.w),
            SvgPicture.asset(
              'assets/icons/location-filled.svg',
              width: 16.w,
              colorFilter: const ColorFilter.mode(
                AppColors.gray400,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                program.location['address'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body3.copyWith(color: AppColors.gray600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgramDescription extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;

  const _ProgramDescription({
    required this.title,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayBody = body.trim().isEmpty ? '정보 없음' : body.trim();
    final bodyStyle = AppTypography.body1.copyWith(
      color: AppColors.gray900,
      decoration: onTap == null ? null : TextDecoration.underline,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            title,
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Text(displayBody, style: bodyStyle, softWrap: true),
          ),
        ),
      ],
    );
  }
}

class _ProgramRelatedInfoDescription extends StatelessWidget {
  final String title;
  final String body;
  final ValueChanged<String> onTapContact;

  const _ProgramRelatedInfoDescription({
    required this.title,
    required this.body,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    final contacts = _splitContacts(body);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              title,
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: contacts.isEmpty
                ? Text(
                    '정보 없음',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.gray900,
                    ),
                  )
                : Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      for (var i = 0; i < contacts.length; i++) ...[
                        GestureDetector(
                          onTap: () => onTapContact(contacts[i]),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            contacts[i],
                            style: AppTypography.body1.copyWith(
                              color: AppColors.gray900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        if (i != contacts.length - 1)
                          Text(
                            '/',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _splitContacts(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\s*(?:/|,|;|\n)\s*'))
        .map((contact) => contact.trim())
        .where((contact) => contact.isNotEmpty)
        .toList();
  }
}
