import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/announcement_model.dart';
import 'package:muntum/screens/mypage/announcement_detail_screen.dart';
import 'package:muntum/services/announcement_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<AnnouncementModel> _announcements = [];
  int _nextPage = 0;
  bool _hasNextPage = true;
  bool _isLoading = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (_isLoading || !_hasNextPage) return;
    setState(() => _isLoading = true);
    try {
      final response = await AnnouncementService().fetchAnnouncements(
        page: _nextPage,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _announcements.addAll(response.content);
        _hasNextPage = response.hasMore;
        _nextPage = response.page + 1;
        _loadedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            child: Builder(
              builder: (context) {
                if (!_loadedOnce && _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                if (_announcements.isEmpty) {
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
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                  itemBuilder: (context, index) {
                    if (index == _announcements.length) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gray900,
                        ),
                      );
                    }
                    final announcement = _announcements[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementDetailScreen(
                              announcement: announcement,
                            ),
                          ),
                        );
                      },
                      child: Padding(
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
                              style: AppTypography.button2.copyWith(
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _formatDate(announcement.createdAt),
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => Divider(
                    height: 28.h,
                    thickness: 1.h,
                    color: AppColors.lineStrong,
                  ),
                  itemCount: _announcements.length + (_isLoading ? 1 : 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
