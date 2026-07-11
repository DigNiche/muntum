import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/announcement_model.dart';
import 'package:muntum/services/announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<AnnouncementModel> _announcementFuture;

  @override
  void initState() {
    super.initState();
    _announcementFuture = _loadAnnouncement();
  }

  Future<AnnouncementModel> _loadAnnouncement() async {
    if (widget.announcement.id.isEmpty) {
      return widget.announcement;
    }
    return AnnouncementService().fetchAnnouncement(widget.announcement.id);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '작성날짜';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.none,
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<AnnouncementModel>(
              future: _announcementFuture,
              initialData: widget.announcement,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '공지사항을 불러오지 못했어요.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  );
                }

                final announcement = snapshot.data ?? widget.announcement;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 36.h, 20.w, 48.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title.isEmpty
                            ? '공지사항 제목'
                            : announcement.title,
                        style: AppTypography.headline1.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        announcement.content.trim().isEmpty
                            ? '공지사항 내용이 없어요.'
                            : announcement.content.trim(),
                        style: AppTypography.body1.copyWith(
                          color: AppColors.gray800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
