import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/mypage/common/terms_detail_screen.dart';
import 'package:muntum/services/terms_service.dart';

/// Opens the published terms and returns only explicit, versioned decisions.
///
/// The privacy checkbox acknowledges the notice only in this sheet. It is never
/// included in the versioned agreements returned to the signup API.
Future<SignupConsent?> showSignUpTermsSheet(
  BuildContext context, {
  TermsService? service,
}) {
  return showModalBottomSheet<SignupConsent>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => _SignUpTermsSheet(service: service ?? TermsService()),
  );
}

class _SignUpTermsSheet extends StatefulWidget {
  const _SignUpTermsSheet({required this.service});
  final TermsService service;

  @override
  State<_SignUpTermsSheet> createState() => _SignUpTermsSheetState();
}

class _SignUpTermsSheetState extends State<_SignUpTermsSheet> {
  late Future<List<TermDocument>> _terms;
  final Set<String> _selected = {};
  bool _privacyNoticeAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _terms = widget.service.fetchSignupTerms();
  }

  void _retry() {
    setState(() {
      _selected.clear();
      _privacyNoticeAcknowledged = false;
      _terms = widget.service.fetchSignupTerms();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 36.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '회원가입을 위해\n약관에 동의해주세요',
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 24.h),
          FutureBuilder<List<TermDocument>>(
            future: _terms,
            builder: (context, snapshot) {
              final isComplete =
                  snapshot.connectionState == ConnectionState.done;
              return _buildTerms(
                isComplete && !snapshot.hasError ? snapshot.data : null,
                hasError: isComplete && snapshot.hasError,
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildTerms(List<TermDocument>? documents, {required bool hasError}) {
    final choices = (documents ?? const <TermDocument>[])
        .where((term) => term.type == 'TERMS_OF_SERVICE' || term.isOptional)
        .toList();
    final requiredTypes = {
      'TERMS_OF_SERVICE',
      for (final term in choices)
        if (term.required) term.type,
    };
    const initialTitles = {
      'TERMS_OF_SERVICE': '서비스 이용약관',
      'PRIVACY_POLICY': '개인정보 처리방침',
    };
    final documentsByType = {
      for (final term in documents ?? []) term.type: term,
    };
    // Show the known layout immediately, without inventing document versions.
    final visibleTypes = documents == null
        ? initialTitles.keys
        : documents
              .where((term) => choices.contains(term) || term.isNotice)
              .map((term) => term.type);
    final hasPrivacyNotice = visibleTypes.contains('PRIVACY_POLICY');
    final allRequiredSelected =
        requiredTypes.every(_selected.contains) &&
        (!hasPrivacyNotice || _privacyNoticeAcknowledged);
    final canContinue = documents != null && allRequiredSelected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: allRequiredSelected
                  ? AppColors.gray900
                  : AppColors.gray300,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _ConsentRow(
            label: '필수 항목 모두 동의하기',
            checked: allRequiredSelected,
            onToggle: () => setState(() {
              for (final type in requiredTypes) {
                if (allRequiredSelected) {
                  _selected.remove(type);
                } else {
                  _selected.add(type);
                }
              }
              _privacyNoticeAcknowledged =
                  hasPrivacyNotice && !allRequiredSelected;
            }),
          ),
        ),
        for (final type in visibleTypes)
          _ConsentRow(
            label:
                '${documentsByType[type]?.title ?? initialTitles[type]} '
                '(${type == 'PRIVACY_POLICY' || requiredTypes.contains(type) ? '필수' : '선택'})',
            checked: type == 'PRIVACY_POLICY'
                ? _privacyNoticeAcknowledged
                : _selected.contains(type),
            onToggle: () => setState(() {
              if (type == 'PRIVACY_POLICY') {
                _privacyNoticeAcknowledged = !_privacyNoticeAcknowledged;
              } else if (!_selected.add(type)) {
                _selected.remove(type);
              }
            }),
            document: documentsByType[type],
            detailsTitle: documentsByType[type]?.title ?? initialTitles[type],
          ),
        if (hasError) ...[
          const Text('약관을 불러오지 못했어요. 다시 시도해주세요.'),
          TextButton(onPressed: _retry, child: const Text('다시 시도')),
        ],
        SizedBox(height: 14.h),
        ButtonSolid(
          text: '회원가입 시작하기',
          textColor: canContinue ? AppColors.white : AppColors.gray400,
          boxColor: canContinue ? AppColors.black : AppColors.gray200,
          onTap: canContinue
              ? () => Navigator.pop(
                  context,
                  SignupConsent([
                    for (final term in choices)
                      TermAgreement(
                        type: term.type,
                        version: term.version,
                        agreed: _selected.contains(term.type),
                      ),
                  ]),
                )
              : null,
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label,
    required this.checked,
    required this.onToggle,
    this.document,
    this.detailsTitle,
  });

  final String label;
  final bool checked;
  final VoidCallback onToggle;
  final TermDocument? document;
  final String? detailsTitle;

  void _openDocument(BuildContext context) {
    final term = document;
    if (term == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TermsDetailScreen(title: term.title, content: term.content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          checked: checked,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Container(
              constraints: BoxConstraints(
                minHeight: detailsTitle == null ? 46.h : 52.h,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/check.svg',
                    width: 20.r,
                    height: 20.r,
                    colorFilter: ColorFilter.mode(
                      checked ? AppColors.gray900 : AppColors.gray300,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (detailsTitle != null)
        IconButton(
          tooltip: '$detailsTitle 자세히 보기',
          icon: SvgPicture.asset(
            'assets/icons/arrow_right-small.svg',
            width: 20.r,
            height: 20.r,
            colorFilter: const ColorFilter.mode(
              AppColors.gray400,
              BlendMode.srcIn,
            ),
          ),
          onPressed: document == null ? null : () => _openDocument(context),
        ),
    ],
  );
}
