import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/screens/mypage/curator/components/curator_application_status_badge.dart';
import 'package:muntum/screens/mypage/curator/curator_application_form_screen.dart';
import 'package:muntum/services/curator_application_service.dart';

class CuratorApplicationDetailScreen extends StatefulWidget {
  const CuratorApplicationDetailScreen({
    super.key,
    required this.applicationId,
    this.initialApplication,
    this.service,
  });

  final String applicationId;
  final CuratorApplicationModel? initialApplication;
  final CuratorApplicationService? service;

  @override
  State<CuratorApplicationDetailScreen> createState() =>
      _CuratorApplicationDetailScreenState();
}

class _CuratorApplicationDetailScreenState
    extends State<CuratorApplicationDetailScreen> {
  late final CuratorApplicationService _service;
  late Future<CuratorApplicationModel> _applicationFuture;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CuratorApplicationService();
    _applicationFuture = _load();
  }

  Future<CuratorApplicationModel> _load() {
    return _service.fetchDetail(widget.applicationId);
  }

  void _reload() {
    setState(() => _applicationFuture = _load());
  }

  Future<void> _edit(CuratorApplicationModel application) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CuratorApplicationFormScreen(
          application: application,
          service: _service,
        ),
      ),
    );
    if (changed == true) {
      _changed = true;
      _reload();
    }
  }

  void _pop() => Navigator.pop(context, _changed);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.text,
              center: '지원 내용',
              leadingIcon: 'arrow_left.svg',
              onLeadingTap: _pop,
            ),
            Expanded(
              child: FutureBuilder<CuratorApplicationModel>(
                future: _applicationFuture,
                initialData: widget.initialApplication,
                builder: (context, snapshot) {
                  final application = snapshot.data;
                  if (application == null &&
                      snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
                    );
                  }
                  if (application == null || snapshot.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: _reload,
                        child: const Text('지원 내용을 불러오지 못했어요. 다시 시도'),
                      ),
                    );
                  }
                  return _DetailContent(
                    application: application,
                    onEdit: application.canEdit
                        ? () => _edit(application)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.application, this.onEdit});

  final CuratorApplicationModel application;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.lineNormal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CuratorApplicationStatusBadge(status: application.status),
                      Text(
                        '${application.formattedCreatedAt} 지원',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  if (application.rejectionReason != null) ...[
                    SizedBox(height: 20.h),
                    _DetailSection(
                      title: '미승인 사유',
                      content: application.rejectionReason!,
                    ),
                    const _SectionDivider(),
                  ] else
                    SizedBox(height: 20.h),
                  _DetailSection(
                    title: '프로그램명',
                    content: application.programName,
                  ),
                  const _SectionDivider(),
                  _DetailSection(title: '한줄소개', content: application.tagline),
                  const _SectionDivider(),
                  _DetailSection(title: '소개글', content: application.curation),
                ],
              ),
            ),
          ),
        ),
        if (onEdit != null)
          Container(
            padding: EdgeInsets.fromLTRB(
              20.w,
              12.h,
              20.w,
              MediaQuery.paddingOf(context).bottom + 16.h,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ButtonSolid(
                text: '지원 내용 수정',
                textColor: AppColors.white,
                boxColor: AppColors.black,
                onTap: onEdit,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.button3.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 8.h),
        Text(
          content.isEmpty ? '-' : content,
          style: AppTypography.body1.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: const Divider(height: 1, color: AppColors.lineNormal),
    );
  }
}
