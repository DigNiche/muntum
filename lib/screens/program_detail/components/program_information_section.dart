import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/program_ended_badge.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';

class ProgramInformationSection extends StatelessWidget {
  final ProgramModel program;
  final VoidCallback? onTapLocation;
  final VoidCallback? onLongPressAddress;
  final ValueChanged<String> onTapContact;
  final VoidCallback? onTapWebsite;
  final VoidCallback? onTapReservation;

  const ProgramInformationSection({
    super.key,
    required this.program,
    this.onTapLocation,
    this.onLongPressAddress,
    required this.onTapContact,
    this.onTapWebsite,
    this.onTapReservation,
  });

  @override
  Widget build(BuildContext context) {
    final contacts = _splitContacts(program.phoneNumber);
    return Column(
      spacing: 4.h,
      children: [
        SizedBox(height: 12.h),
        _LocationDescription(
          program: program,
          onTap: onTapLocation,
          onLongPress: onLongPressAddress,
        ),
        Divider(color: AppColors.lineNormal, thickness: 1.sp),
        _ProgramDescription(
          title: '기간',
          body: program.detailDateText,
          bodyTrailing: program.isEnded ? const ProgramEndedBadge() : null,
        ),
        Divider(color: AppColors.lineNormal, thickness: 1.sp),
        _ProgramDescription(title: '시간', body: program.availableTime),
        Divider(color: AppColors.lineNormal, thickness: 1.sp),
        _ProgramDescription(title: '가격', body: program.cost),
        Divider(color: AppColors.lineNormal, thickness: 1.sp),
        _ProgramDescription(title: '예약', body: program.reservationType.label),
        if (contacts.isNotEmpty) ...[
          Divider(color: AppColors.lineNormal, thickness: 1.sp),
          _ProgramRelatedInfoDescription(
            title: '문의처',
            contacts: contacts,
            onTapContact: onTapContact,
          ),
        ],
        if (program.link.trim().isNotEmpty ||
            program.reservationUrl.trim().isNotEmpty) ...[
          Divider(color: AppColors.lineNormal, thickness: 1.sp),
          _ProgramLinkDescription(
            link: program.link,
            onTap: onTapWebsite,
            reservationUrl: program.reservationUrl,
            onTapReservation: onTapReservation,
          ),
        ],
      ],
    );
  }
}

class _LocationDescription extends StatelessWidget {
  final ProgramModel program;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _LocationDescription({
    required this.program,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 70.w,
                child: Text(
                  '위치',
                  style: AppTypography.button2.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Text(
                  program.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body1.copyWith(color: AppColors.gray900),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 90.w),
              Padding(
                padding: EdgeInsets.only(top: 3.5.h),
                child: SvgPicture.asset(
                  'assets/icons/location-filled.svg',
                  width: 16.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
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
      ),
    );
  }
}

class _ProgramLinkDescription extends StatelessWidget {
  final String link;
  final VoidCallback? onTap;
  final String reservationUrl;
  final VoidCallback? onTapReservation;
  const _ProgramLinkDescription({
    required this.link,
    required this.onTap,
    required this.reservationUrl,
    required this.onTapReservation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            '링크',
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        SizedBox(width: 20.w),
        if (link.trim().isNotEmpty)
          _ProgramLinkIcon(
            key: const ValueKey('program-website-link'),
            onTap: onTap,
            icon: SvgPicture.asset(
              'assets/icons/captive_portal.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        if (link.trim().isNotEmpty && reservationUrl.trim().isNotEmpty)
          SizedBox(width: 8.w),
        if (reservationUrl.trim().isNotEmpty)
          _ProgramLinkIcon(
            key: const ValueKey('program-reservation-link'),
            onTap: onTapReservation,
            icon: const _ReservationIcon(),
          ),
      ],
    );
  }
}

class _ProgramLinkIcon extends StatelessWidget {
  const _ProgramLinkIcon({super.key, required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(8.r),
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(99),
        ),
        child: icon,
      ),
    );
  }
}

// reservation_icon.svg contains a base64 PNG pattern, which flutter_svg cannot
// paint. Decode the image in that asset directly so the supplied icon is visible.
class _ReservationIcon extends StatelessWidget {
  const _ReservationIcon();

  static final Future<Uint8List> _imageBytes = _loadImageBytes();

  static Future<Uint8List> _loadImageBytes() async {
    final svg = await rootBundle.loadString(
      'assets/icons/reservation_icon.svg',
    );
    final image = RegExp(r'data:image/png;base64,([^"\s]+)').firstMatch(svg);
    if (image == null) {
      throw const FormatException('Reservation icon image is missing');
    }
    return base64Decode(image.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageBytes,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            color: AppColors.black,
            colorBlendMode: BlendMode.srcIn,
          );
        }
        return const Icon(Icons.event_available, color: AppColors.black);
      },
    );
  }
}

class _ProgramDescription extends StatelessWidget {
  final String title;
  final String body;
  final Widget? bodyTrailing;

  const _ProgramDescription({
    required this.title,
    required this.body,
    this.bodyTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final displayBody = body.trim().isEmpty ? '정보 없음' : body.trim();
    final bodyStyle = AppTypography.body1.copyWith(color: AppColors.gray900);

    return Row(
      crossAxisAlignment: displayBody.contains('\n')
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: displayBody.contains('\n')
              ? EdgeInsets.only(top: 2.h)
              : null,
          width: 70.w,
          child: Text(
            title,
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: bodyTrailing == null
              ? Text(displayBody, style: bodyStyle, softWrap: true)
              : Wrap(
                  spacing: 6.w,
                  runSpacing: 2.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(displayBody, style: bodyStyle, softWrap: true),
                    bodyTrailing!,
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProgramRelatedInfoDescription extends StatelessWidget {
  final String title;
  final List<String> contacts;
  final ValueChanged<String> onTapContact;

  const _ProgramRelatedInfoDescription({
    required this.title,
    required this.contacts,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Wrap(
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
    );
  }
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
