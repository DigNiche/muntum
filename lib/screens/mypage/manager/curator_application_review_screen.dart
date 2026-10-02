import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/user_profile_sheet.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/services/admin_user_service.dart';
import 'package:muntum/services/curator_application_service.dart';
import 'package:muntum/utils/app_toast.dart';

class CuratorApplicationReviewScreen extends StatefulWidget {
  const CuratorApplicationReviewScreen({
    super.key,
    required this.applicationId,
    required this.initialApplication,
    required this.service,
    this.userService,
  });

  final String applicationId;
  final CuratorApplicationModel initialApplication;
  final CuratorApplicationService service;
  final AdminUserService? userService;

  @override
  State<CuratorApplicationReviewScreen> createState() =>
      _CuratorApplicationReviewScreenState();
}

class _CuratorApplicationReviewScreenState
    extends State<CuratorApplicationReviewScreen> {
  late Future<CuratorApplicationModel> _applicationFuture;
  bool _isReviewing = false;
  late final AdminUserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = widget.userService ?? AdminUserService();
    _applicationFuture = widget.service.fetchDetail(widget.applicationId);
  }

  void _showApplicantProfile(CuratorApplicantModel applicant) {
    final userFuture = _userService
        .findUserById(userId: applicant.userId, email: applicant.email)
        .catchError((Object _) => null);
    showModalBottomSheet<void>(
      context: context,
      barrierColor: AppColors.dimMedium,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<AdminUserModel?>(
        future: userFuture,
        builder: (context, snapshot) =>
            UserProfileSheet(user: snapshot.data, applicant: applicant),
      ),
    );
  }

  Future<void> _approve() async {
    if (_isReviewing) return;
    setState(() => _isReviewing = true);
    try {
      await widget.service.review(
        id: widget.applicationId,
        status: CuratorApplicationStatus.approved,
      );
      if (!mounted) return;
      showAppToast(context, '승인되었습니다.');
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '승인 처리하지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectReasonSheet();
    if (!mounted || reason == null) return;
    setState(() => _isReviewing = true);
    try {
      await widget.service.review(
        id: widget.applicationId,
        status: CuratorApplicationStatus.rejected,
        rejectReason: reason,
      );
      if (!mounted) return;
      showAppToast(context, '반려되었습니다.');
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '반려 처리하지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  Future<String?> _showRejectReasonSheet() {
    String? selected;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.dimMedium,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반려 사유 선택',
                  style: AppTypography.title4.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 20.h),
                for (final reason in _rejectReasons) ...[
                  _RejectReasonTile(
                    reason: reason,
                    selected: selected == reason.code,
                    onTap: () => setSheetState(() => selected = reason.code),
                  ),
                  SizedBox(height: 10.h),
                ],
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ButtonSolid(
                          text: '취소',
                          textColor: AppColors.gray900,
                          boxColor: AppColors.white,
                          border: Border.all(color: AppColors.lineStrong),
                          padding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ButtonSolid(
                          text: '반려 확정',
                          textColor: selected == null
                              ? AppColors.gray400
                              : AppColors.white,
                          boxColor: selected == null
                              ? AppColors.gray100
                              : AppColors.black,
                          padding: EdgeInsets.zero,
                          onTap: selected == null
                              ? null
                              : () => Navigator.pop(sheetContext, selected),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FutureBuilder<CuratorApplicationModel>(
        future: _applicationFuture,
        initialData: widget.initialApplication,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                SizedBox(height: 50.h),
                AppBarWidget(
                  centerType: AppBarCenterType.text,
                  leadingIcon: 'arrow_left.svg',
                  center: '지원 상세',
                  onLeadingTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: _ErrorView(
                    onRetry: () => setState(() {
                      _applicationFuture = widget.service.fetchDetail(
                        widget.applicationId,
                      );
                    }),
                  ),
                ),
              ],
            );
          }
          final application = snapshot.data ?? widget.initialApplication;
          return Column(
            children: [
              SizedBox(height: 50.h),
              AppBarWidget(
                centerType: AppBarCenterType.text,
                leadingIcon: 'arrow_left.svg',
                center: '지원 상세',
                onLeadingTap: () => Navigator.pop(context),
              ),
              if (application.status == CuratorApplicationStatus.rejected)
                _RejectionBanner(message: application.rejectionReason),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
                  child: _ApplicationDetails(
                    application: application,
                    onApplicantTap: application.applicant == null
                        ? null
                        : () => _showApplicantProfile(application.applicant!),
                  ),
                ),
              ),
              if (application.status == CuratorApplicationStatus.pending)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: ButtonSolid(
                              text: '반려',
                              textColor: AppColors.gray900,
                              boxColor: AppColors.white,
                              border: Border.all(color: AppColors.lineStrong),
                              padding: EdgeInsets.zero,
                              onTap: _isReviewing ? null : _reject,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: ButtonSolid(
                              text: _isReviewing ? '처리 중' : '승인',
                              textColor: AppColors.white,
                              boxColor: AppColors.black,
                              padding: EdgeInsets.zero,
                              onTap: _isReviewing ? null : _approve,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationDetails extends StatelessWidget {
  const _ApplicationDetails({
    required this.application,
    required this.onApplicantTap,
  });

  final CuratorApplicationModel application;
  final VoidCallback? onApplicantTap;

  @override
  Widget build(BuildContext context) {
    final applicant = application.applicant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('application-applicant-profile'),
          onTap: onApplicantTap,
          child: Row(
            children: [
              _ApplicantAvatar(imageUrl: applicant?.profileImageUrl),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant?.nickname ?? '닉네임 미설정',
                      style: AppTypography.button3.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      applicant?.email ?? '',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Divider(height: 1.h, color: AppColors.lineNormal),
        SizedBox(height: 24.h),
        Text(
          '작성 내용',
          style: AppTypography.headline2.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 24.h),
        _DetailField(label: '프로그램명', value: application.programName),
        SizedBox(height: 24.h),
        _DetailField(label: '한줄소개', value: application.tagline),
        SizedBox(height: 24.h),
        _DetailField(label: '소개글', value: application.curation),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption2.copyWith(color: AppColors.gray400),
        ),
        SizedBox(height: 8.h),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTypography.body3.copyWith(
            color: AppColors.gray900,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8D9),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Text(
        '반려\n${message ?? '지원서가 반려되었습니다.'}',
        style: AppTypography.caption2.copyWith(
          color: AppColors.warning,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: 48.r,
      height: 48.r,
      fit: BoxFit.cover,
    );
    final url = imageUrl?.trim();
    return ClipOval(
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: 48.r,
              height: 48.r,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _RejectReasonTile extends StatelessWidget {
  const _RejectReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _RejectReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? AppColors.gray900 : AppColors.lineStrong,
          ),
        ),
        child: Text(
          reason.message,
          style: AppTypography.body3.copyWith(color: AppColors.gray900),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(onPressed: onRetry, child: const Text('다시 시도')),
    );
  }
}

class _RejectReason {
  const _RejectReason(this.code, this.message);

  final String code;
  final String message;
}

const _rejectReasons = [
  _RejectReason(
    'INSUFFICIENT_INFO',
    '제출하신 정보가 부족하여 승인되지 않았습니다. 보완 후 재신청해 주세요.',
  ),
  _RejectReason(
    'GUIDELINE_MISMATCH',
    '작성 가이드라인과 맞지 않아 승인되지 않았습니다. 확인 후 재신청해주세요.',
  ),
  _RejectReason(
    'PROGRAM_MISMATCH',
    '프로그램 성격과 맞지 않아 승인되지 않았습니다. 내용 확인 후 재신청해주세요.',
  ),
];
