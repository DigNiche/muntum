import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/mypage/common/terms_detail_screen.dart';
import 'package:muntum/services/terms_service.dart';
import 'package:muntum/utils/app_toast.dart';

/// Displays recorded optional consents and current published documents.
class TermsSettingsScreen extends StatefulWidget {
  /// Creates a terms-management page using the shared terms API.
  const TermsSettingsScreen({super.key, this.service});

  /// The injectable terms service.
  final TermsService? service;

  @override
  State<TermsSettingsScreen> createState() => _TermsSettingsScreenState();
}

class _TermsSettingsScreenState extends State<TermsSettingsScreen> {
  late final TermsService _service;
  List<TermDocument>? _documents;
  UserTermsState? _state;
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TermsService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _service.fetchActive(),
        _service.fetchMyConsents(),
      ]);
      if (!mounted) return;
      setState(() {
        _documents = results[0] as List<TermDocument>;
        _state = results[1] as UserTermsState;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(String type, bool agreed, TermDocument? document) async {
    if (_saving || (agreed && document == null)) return;
    setState(() => _saving = true);
    try {
      final state = await _service.updateOptional([
        TermAgreement(
          type: type,
          agreed: agreed,
          version: agreed ? document!.version : null,
        ),
      ]);
      if (mounted) setState(() => _state = state);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException &&
          (error.code == 'T007' || error.code == 'T009')) {
        // A newly loaded version needs a new decision, never an automatic retry.
        await _load();
      }
      if (mounted) {
        showAppToast(
          context,
          error is ApiException
              ? error.message
              : '변경 결과를 확인하지 못했어요. 다시 조회해주세요.',
          isError: true,
        );
        if (error is! ApiException) await _load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _open(TermDocument document) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TermsDetailScreen(title: document.title, content: document.content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Column(
        children: [
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '선택 약관 관리',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    ),
  );

  Widget _buildContent() {
    if (_loading) return const PageLoadingSkeleton.rows();
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error is ApiException
                  ? (_error as ApiException).message
                  : '약관 정보를 불러오지 못했어요.',
            ),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    final documents = _documents!;
    final state = _state!;
    final optional = {
      for (final term in documents.where((term) => term.isOptional))
        term.type: term,
    };
    final visibleTypes = optionalTermTypes.where(
      (type) =>
          optional.containsKey(type) || state.optionalConsents[type] == true,
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      children: [
        for (final term in documents.where((term) => !term.isOptional))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(term.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(term),
          ),
        if (visibleTypes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Text('현재 동의할 수 있는 선택 약관이 없습니다.'),
          ),
        for (final type in visibleTypes) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(optional[type]?.title ?? _optionalTitle(type)),
            subtitle: optional[type] == null
                ? const Text('현재 게시되지 않은 약관입니다. 기존 동의를 철회할 수 있어요.')
                : null,
            value: state.optionalConsents[type] == true,
            onChanged: _saving
                ? null
                : (value) => _change(type, value, optional[type]),
          ),
          if (optional[type] != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _open(optional[type]!),
                child: const Text('약관 내용 보기'),
              ),
            ),
        ],
      ],
    );
  }

  String _optionalTitle(String type) => switch (type) {
    'MARKETING_PUSH' => '앱 푸시 마케팅 수신',
    'MARKETING_EMAIL' => '이메일 마케팅 수신',
    'LOCATION_TERMS' => '위치기반 서비스 이용약관',
    'THIRD_PARTY_OFFER' => '제3자 정보 제공',
    _ => type,
  };
}
