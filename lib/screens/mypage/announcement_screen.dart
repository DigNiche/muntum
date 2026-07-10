import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/announcement_model.dart';
import 'package:muntum/services/announcement_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _loadAnnouncements();
  }

  Future<List<AnnouncementModel>> _loadAnnouncements() async {
    return (await AnnouncementService().fetchAnnouncements(size: 100)).content;
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
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '공지사항',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<AnnouncementModel>>(
              future: _announcementsFuture,
              builder: (context, snapshot) {
                final announcements =
                    snapshot.data ?? const <AnnouncementModel>[];
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                if (announcements.isEmpty) {
                  return Center(
                    child: Text(
                      '등록된 공지사항이 없어요.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title.isEmpty
                                ? '공지사항 제목'
                                : announcement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline1.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(announcement.createdAt),
                            style: AppTypography.body3.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => Divider(
                    height: 28.h,
                    thickness: 1.h,
                    color: AppColors.lineStrong,
                  ),
                  itemCount: announcements.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
